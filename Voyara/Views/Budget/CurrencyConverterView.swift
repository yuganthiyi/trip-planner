import SwiftUI

struct CurrencyConverterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var amount: String = "100"
    @State private var fromCurrency: String = "USD"
    @State private var toCurrency: String = "EUR"
    
    // Mock Exchange Rates against USD
    let exchangeRates: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 150.2,
        "AUD": 1.53,
        "CAD": 1.35,
        "CHF": 0.88,
        "CNY": 7.19,
        "INR": 82.9
    ]
    
    var currencies: [String] {
        exchangeRates.keys.sorted()
    }
    
    var convertedAmount: Double {
        guard let input = Double(amount),
              let fromRate = exchangeRates[fromCurrency],
              let toRate = exchangeRates[toCurrency] else { return 0 }
        
        let amountInUSD = input / fromRate
        return amountInUSD * toRate
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: VoyaraTheme.spacing24) {
                        // Header
                        ZStack {
                            Circle()
                                .fill(VoyaraColors.primary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "dollarsign.arrow.circlepath")
                                .font(.system(size: 36))
                                .foregroundColor(VoyaraColors.primary)
                        }
                        .padding(.top, VoyaraTheme.spacing32)
                        
                        Text("Currency Converter")
                            .font(VoyaraTypography.displayMedium)
                            .foregroundColor(VoyaraColors.text)
                        
                        Text("Calculate exchange rates instantly even when offline.")
                            .font(VoyaraTypography.bodyMedium)
                            .foregroundColor(VoyaraColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, VoyaraTheme.spacing32)
                        
                        // Converter Card
                        VoyaraCard {
                            VStack(spacing: VoyaraTheme.spacing20) {
                                // From Currency
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("From")
                                            .font(VoyaraTypography.captionSmall)
                                            .foregroundColor(VoyaraColors.textSecondary)
                                        Picker("From Currency", selection: $fromCurrency) {
                                            ForEach(currencies, id: \.self) { currency in
                                                Text(currency).tag(currency)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(VoyaraColors.text)
                                        .font(VoyaraTypography.headlineMedium)
                                    }
                                    
                                    Spacer()
                                    
                                    TextField("Amount", text: $amount)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(VoyaraTypography.displayMedium)
                                        .foregroundColor(VoyaraColors.primary)
                                }
                                
                                // Swap Button
                                Button(action: {
                                    let temp = fromCurrency
                                    fromCurrency = toCurrency
                                    toCurrency = temp
                                }) {
                                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(VoyaraColors.accent)
                                }
                                .padding(.vertical, 8)
                                
                                // To Currency
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("To")
                                            .font(VoyaraTypography.captionSmall)
                                            .foregroundColor(VoyaraColors.textSecondary)
                                        Picker("To Currency", selection: $toCurrency) {
                                            ForEach(currencies, id: \.self) { currency in
                                                Text(currency).tag(currency)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(VoyaraColors.text)
                                        .font(VoyaraTypography.headlineMedium)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.2f", convertedAmount))
                                        .font(VoyaraTypography.displayMedium)
                                        .foregroundColor(VoyaraColors.text)
                                }
                            }
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(VoyaraColors.primary)
                }
            }
        }
    }
}
