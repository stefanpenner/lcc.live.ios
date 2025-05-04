import SwiftUI

struct ContentView: View {
    // TODO: hard-coded for now until we have an API
    let lccImages = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0NvbGxpbnNfU25vd19TdGFrZS5qcGc=",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNzAuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL1N1cGVyaW9yLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0hpZ2hydXN0bGVyLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL3N1Z2FyX3BlYWsuanBn",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL2NvbGxpbnNfZHRjLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hcHAucHJpc21jYW0uY29tL3B1YmxpYy9oZWxwZXJzL3JlYWx0aW1lX3ByZXZpZXcucGhwP2M9ODgmcz03MjA=",
        "https://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80OGZjMjIzYzBlZDg4NDc0ZWNjMmY4ODRiZjM5ZGU2My9tZWRpdW0=",
        "https://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80NGNmZmY0ZmYyYTIxOGExMTc4ZGJiMTA1ZDk1ODQ2YS9tZWRpdW0=",
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzU3ODA3NTRmLThkYTEtNDIyMy1hYjhhLTY3NTVkODRjYmMxMC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzYxYjI0OTBiZTEwMWMwMGI5YzQ4Mzc0Zi9zbmFwc2hvdA=="
    ]
    
    let bccImages = [
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTYuanBlZw=="
    ]
    
    var body: some View {
        TabView {
            PhotoTabView(images: lccImages, title: "lcc", icon: "leaf")
            PhotoTabView(images: bccImages, title: "bcc", icon: "flame")
        }
        .tabViewStyle(.automatic)
    }
}

#Preview {
    ContentView()
}
