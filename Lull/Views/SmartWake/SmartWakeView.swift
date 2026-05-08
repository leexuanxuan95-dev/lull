import SwiftUI

struct SmartWakeView: View {
    @EnvironmentObject var app: AppStore
    @EnvironmentObject var subscription: SubscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var wakeDate: Date = Date()

    var body: some View {
        ZStack {
            MidnightBackground()

            ScrollView {
                VStack(spacing: 22) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("smart wake")
                            .font(LullFonts.display(30))
                            .foregroundStyle(LullColors.textPrimary)
                        Text("Pro · 20 minutes before alarm, nature sounds gradually wake you. or Lull narrates a custom good-morning in your chosen voice.")
                            .font(LullFonts.prose(14))
                            .foregroundStyle(LullColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    LullCard {
                        VStack(spacing: 14) {
                            Toggle(isOn: $app.smartWakeOn) {
                                Text("smart wake")
                                    .font(LullFonts.ui(16, weight: .medium))
                                    .foregroundStyle(LullColors.textPrimary)
                            }
                            .tint(LullColors.warmLamp)

                            Divider().background(LullColors.hairline)

                            DatePicker("wake at",
                                       selection: $wakeDate,
                                       displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .colorScheme(.dark)
                                .frame(height: 130)
                                .clipped()
                                .disabled(!app.smartWakeOn)
                                .opacity(app.smartWakeOn ? 1 : 0.4)
                        }
                    }

                    LullCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("how it works")
                                .font(LullFonts.ui(13, weight: .medium))
                                .foregroundStyle(LullColors.textMuted)
                                .textCase(.uppercase)

                            ForEach([
                                "20 min before — soft nature sounds begin (rain, river, wind)",
                                "10 min before — Lull narrates a custom good-morning",
                                "at the time — gentle haptic on Apple Watch (if connected)"
                            ], id: \.self) { line in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("·")
                                        .foregroundStyle(LullColors.warmLamp)
                                    Text(line)
                                        .font(LullFonts.prose(14))
                                        .foregroundStyle(LullColors.textSecondary)
                                }
                            }
                        }
                    }

                    if !subscription.isPro {
                        unlockCta
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            var comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
            comps.hour = app.smartWakeHour
            comps.minute = app.smartWakeMinute
            wakeDate = Calendar.current.date(from: comps) ?? Date()
        }
        .onChange(of: wakeDate) { _, new in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: new)
            app.smartWakeHour = comps.hour ?? 7
            app.smartWakeMinute = comps.minute ?? 0
        }
        .onChange(of: app.smartWakeOn) { _, on in
            if on && !subscription.isPro {
                app.smartWakeOn = false
                app.paywallPresented = true
            }
        }
    }

    private var unlockCta: some View {
        LullCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("smart wake is part of Pro.")
                    .font(LullFonts.ui(15, weight: .medium))
                    .foregroundStyle(LullColors.textPrimary)
                Text("$9.99/mo or $69/yr · also unlocks premium voices, Apple Watch, and unlimited stories.")
                    .font(LullFonts.prose(13))
                    .foregroundStyle(LullColors.textSecondary)
                LullPrimaryButton(title: "go Pro") { app.paywallPresented = true }
            }
        }
    }
}
