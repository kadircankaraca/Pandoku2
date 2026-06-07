//
//  SettingsView.swift
//  Pandoku 2
//
//  Created by Kadir on 13.02.2026.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @AppStorage("appTheme") private var selectedTheme: ThemeOption = .system

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Appearance Section
                Section {
                    ThemePickerView(selectedTheme: $selectedTheme)
                } header: {
                    Text("settings.appearance".localized)
                }

                // MARK: - Language Section
                Section {
                    LanguagePickerView(selectedLanguage: $localizationManager.currentLanguage)
                } header: {
                    Text("settings.language".localized)
                } footer: {
                    Text("settings.language_footer".localized)
                        .font(.caption)
                }

                // MARK: - About Section
                Section {
                    AboutRow()
                } header: {
                    Text("settings.about".localized)
                }

                // MARK: - Support Section
                Section {
                    Button(action: requestReview) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("settings.rate_app".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: shareApp) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("settings.share_app".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/kadircankaraca/Pandoku-2")!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.green)
                            Text("about.social_github".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/kadircankaraca/Pandoku-2#privacy-policy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.orange)
                            Text("about.privacy_policy".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("settings.support".localized)
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func shareApp() {
        let activityVC = UIActivityViewController(
            activityItems: ["Check out Sudo - A classic Sudoku puzzle game!\nhttps://apps.apple.com/app/idXXXXXXXXX"],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Theme Picker

struct ThemePickerView: View {
    @Binding var selectedTheme: ThemeOption
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        Picker(selection: $selectedTheme) {
            ForEach(ThemeOption.allCases) { option in
                HStack {
                    Image(systemName: option.icon)
                        .foregroundColor(.secondary)
                    Text(option.localizedKey.localized)
                        .foregroundColor(.primary)
                }
                .tag(option)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.inline)
        .labelsHidden()
    }
}

// MARK: - Language Picker

struct LanguagePickerView: View {
    @Binding var selectedLanguage: LanguageOption
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        Picker(selection: $selectedLanguage) {
            ForEach(LanguageOption.allCases) { option in
                HStack {
                    Text(option.flag)
                        .font(.title2)
                    Text(option.localizedKey.localized)
                        .foregroundColor(.primary)
                }
                .tag(option)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.inline)
        .labelsHidden()
    }
}

// MARK: - About Row

struct AboutRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("app.name".localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("app.tagline".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // App logo
                if let logoImage = UIImage(named: "AppLogo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "number.square.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                }
            }

            Divider()

            // Version info
            VStack(alignment: .leading, spacing: 4) {
                Text("about.version".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("about.version_number".localized)
                    .font(.caption)
                    .foregroundStyle(.primary)

                Text("about.developer".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("about.made_with_love".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Features list
            VStack(alignment: .leading, spacing: 6) {
                Text("about.features".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                FeatureRow(icon: "checkmark.circle.fill", textKey: "about.feature_1")
                FeatureRow(icon: "checkmark.circle.fill", textKey: "about.feature_2")
                FeatureRow(icon: "checkmark.circle.fill", textKey: "about.feature_3")
                FeatureRow(icon: "checkmark.circle.fill", textKey: "about.feature_4")
            }
        }
        .padding(.vertical, 8)
    }
}

struct FeatureRow: View {
    let icon: String
    let textKey: String
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.green)
            Text(textKey.localized)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(LocalizationManager.shared)
}
