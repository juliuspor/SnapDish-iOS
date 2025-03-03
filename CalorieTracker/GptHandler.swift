import Foundation
import UIKit

class OpenAIHandler {
    static let apiKey = "XXXXXXXXXXXXXXX" // Replace with your actual API key

    static func uploadImage(_ image: UIImage, withPrompt prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to get image data"])))
            return
        }

        let base64Image = imageData.base64EncodedString()

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]

        let payload: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt], // Add your text prompt here
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                    ]
                ]
            ],
            "max_tokens": 300
        ]

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        let jsonData = try? JSONSerialization.data(withJSONObject: payload)
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors in the network request
                if let error = error {
                    completion(.failure(error))
                    return
                }

                // Log the raw response for debugging
                if let data = data, let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(rawResponse)")
                }
            // Ensure the response is an HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])))
                return
            }

            // Check the status code of the response
            guard httpResponse.statusCode == 200 else {
                var errorMessage = "Request failed with status code: \(httpResponse.statusCode)"
                if let data = data, let errorResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let errorDetails = errorResponse["error"] as? [String: Any],
                   let message = errorDetails["message"] as? String {
                    errorMessage = message
                }
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            // Process the response data
            do {
                    if let responseData = data,
                       let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else {
                        completion(.failure(NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        

    }
}

