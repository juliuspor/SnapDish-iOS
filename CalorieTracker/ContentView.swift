import SwiftUI

struct ContentView: View {
    @State private var showingCamera = false
    @State private var image: UIImage?
    @State private var imageDescription: String = ""
    @State private var isLoading = false  // To track the loading state
    @State private var errorMessage: String?  // To display error messages
    @State private var buzzwords: String = "" // User input for buzzwords

    var body: some View {
        NavigationView {
            ZStack {
                Color.accentColor.edgesIgnoringSafeArea(.all)

                VStack {
                    TextField("Gib Stichworte ein (z.B. Quinoa, Tofu, ...)", text: $buzzwords)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: {
                        self.showingCamera = true
                    }) {
                        Text("Take a pic 😍")
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showingCamera) {
                        CameraView(isShown: $showingCamera, image: $image)
                    }

                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Button(action: {
                                isLoading = true
                                errorMessage = nil
                                if let image = self.image {
                                    let textPrompt = """
                                    Die Buzzwords: \(buzzwords)
                                    
                                    Schätze bitte die Kalorien der aufgelisteten Nahrungsmittel ab. Hierzu nimm bitte Durschnittswerte an und vermeide Bandbreiten. Falls ein Bild hochgeladen wird, gib die gleiche Einschätzung für das vermutete Gericht ab. Triff bitte Annahmen selbstständig. Falls Buzzwords zu einem Bild zu finden sind, nutze diese bitte um die Lebensmittel korrekt zu identifizieren oder nähere Informationen dazu zu bekommen. Die Anmerkungen müssen aber nicht zwangsläufig alle Lebensmittel auf dem Bild zeigen. Deswegen schaue bitte selbst genau hin.
                                     
                                    Das Ergebnis bitte immer in Deutsch als Tabelle mit folgenden Spalten ausgeben: Name des nahrungsmittel, geschätzte Kalorien. Am Ende der Tabelle fasse bitte die Summe der Kalorien zusammen. Gib Deine Kalorienschätzung als feste Zahl an - also ohne ca. etc.
                                     
                                    Falls Du ein Lebensmittel nicht kennst, versuche die notwendigen Informationen im Internet zu recherchieren.
                                     
                                    Zudem gib eine Einschätzung auf einer Skala von 1 bis 5 darüber ab, wie Gesund das gesamte Essen war. 5 ist gleichwertig mit der höchsten Gesundheitsstufe. 1 mit der geringsten. Bei der Einschätzung schaue bitte das die beste Einschätzung Lebensmittel mit wenig Zucker betrifft, niedrigem GI und hohem Ballaststoff/Nährwertanteil.
                                     
                                    Weiterhin gib bitte eine Einschätzung des glykämischen Index wieder.
                                    """
                                    OpenAIHandler.uploadImage(image, withPrompt: textPrompt) { result in
                                        isLoading = false
                                        switch result {
                                        case .success(let description):
                                            self.imageDescription = description
                                        case .failure(let error):
                                            self.errorMessage = error.localizedDescription
                                        }
                                    }
                                }
                            }) {
                                Text("🐘 Calculate my calories 🐘")
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }

                    // TextEditor for the response
                    TextEditor(text: $imageDescription)
                        .padding()
                        .cornerRadius(10)
                        .frame(minHeight: 100)

                    // Display error message
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
    }
}

