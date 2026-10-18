import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.down.on.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .foregroundColor(.accentColor)
            
            Text("Plupo")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text("Утилита для упрощения перетаскивания файлов (Drag & Drop) на macOS.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "sidebar.left", title: "Боковая панель", description: "Появляется у края экрана при начале перетаскивания файлов.")
                FeatureRow(icon: "lock.fill", title: "Блокировка файлов", description: "Зафиксируйте файлы на полке для многократного использования.")
                FeatureRow(icon: "eye.fill", title: "Быстрый просмотр", description: "Быстро просматривайте файлы по двойному клику.")
                FeatureRow(icon: "gearshape.fill", title: "Гибкие настройки", description: "Настраивайте положение, размер карточек и поведение через меню-бар.")
            }
            .padding()
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            
            Text("Приложение работает в фоновом режиме. Управлять им можно через иконку в меню-баре (Menu Bar) сверху.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Открыть настройки") {
                WindowManager.shared.showPreferencesWindow()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(30)
        .frame(width: 450, height: 500)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
