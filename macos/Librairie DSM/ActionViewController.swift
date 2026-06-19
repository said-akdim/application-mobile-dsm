import UIKit
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let items = extensionContext?.inputItems as? [NSExtensionItem], !items.isEmpty else {
            return
        }

        for item in items {
            guard let providers = item.attachments, !providers.isEmpty else { continue }

            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    // Capture a weak reference to imageView to avoid capturing self in a @Sendable context
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak iv = self.imageView] (item, error) in
                        if let error = error {
                            NSLog("Failed to load item for UTType.image: \(error.localizedDescription)")
                            return
                        }
                        guard let url = item as? URL else { return }
                        Task {
                            do {
                                let data = try Data(contentsOf: url)
                                guard let image = UIImage(data: data) else { return }
                                await MainActor.run {
                                    iv?.image = image
                                }
                            } catch {
                                NSLog("Failed to read image data from URL: \(error.localizedDescription)")
                            }
                        }
                    }
                    // Only handle one image
                    return
                }
            }
        }
    }

    @IBAction func done() {
        extensionContext?.completeRequest(returningItems: extensionContext?.inputItems, completionHandler: nil)
    }
}
