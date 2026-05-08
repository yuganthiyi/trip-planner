import SwiftUI

struct BudgetTabView: View {
    @EnvironmentObject var tripViewModel: TripViewModel
    @State private var showAddExpense = false
    @State private var showCurrencyConverter = false
    @State private var selectedTrip: Trip?
    
    var totalSpent: Decimal { tripViewModel.totalBudgetSpent }
    var totalBudget: Decimal { tripViewModel.trips.reduce(0) { $0 + $1.budget } }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VoyaraColors.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: VoyaraTheme.spacing24) {
                        // Overall Summary
                        VoyaraCard {
                            VStack(spacing: VoyaraTheme.spacing16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: VoyaraTheme.spacing4) {
                                        Text("Total Spending").font(VoyaraTypography.bodySmall).foregroundColor(VoyaraColors.textSecondary)
                                        Text("$\(NSDecimalNumber(decimal: totalSpent).intValue)")
                                            .font(VoyaraTypography.displayLarge).foregroundColor(VoyaraColors.text)
                                        Text("of $\(NSDecimalNumber(decimal: totalBudget).intValue) budget")
                                            .font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                                    }
                                    Spacer()
                                    let pct = totalBudget > 0 ? Double(truncating: (totalSpent / totalBudget) as NSNumber) : 0
                                    CircularProgressView(progress: min(pct, 1.0), lineWidth: 8, size: 70, color: pct > 0.9 ? VoyaraColors.error : VoyaraColors.primary)
                                        .overlay(Text("\(Int(pct * 100))%").font(VoyaraTypography.labelSmall).foregroundColor(VoyaraColors.text))
                                }
                                
                                HStack(spacing: VoyaraTheme.spacing16) {
                                    budgetStat(icon: "arrow.up.circle", label: "Spent", value: "$\(NSDecimalNumber(decimal: totalSpent).intValue)", color: VoyaraColors.error)
                                    budgetStat(icon: "arrow.down.circle", label: "Remaining", value: "$\(NSDecimalNumber(decimal: totalBudget - totalSpent).intValue)", color: VoyaraColors.success)
                                }
                            }
                        }
                        .padding(.horizontal, VoyaraTheme.spacing24)
                        
                        // Category Breakdown
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                            SectionHeader(title: "By Category").padding(.horizontal, VoyaraTheme.spacing24)
                            
                            let categories = categoryBreakdown()
                            if !categories.isEmpty {
                                VStack(spacing: VoyaraTheme.spacing8) {
                                    ForEach(categories, id: \.category) { item in
                                        HStack(spacing: VoyaraTheme.spacing12) {
                                            Image(systemName: item.category.icon)
                                                .foregroundColor(.white).font(.system(size: 12, weight: .semibold))
                                                .frame(width: 32, height: 32)
                                                .background(item.category.color)
                                                .cornerRadius(8)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.category.rawValue).font(VoyaraTypography.bodyMedium).foregroundColor(VoyaraColors.text)
                                                GeometryReader { g in
                                                    ZStack(alignment: .leading) {
                                                        RoundedRectangle(cornerRadius: 2).fill(VoyaraColors.surfaceVariant).frame(height: 4)
                                                        RoundedRectangle(cornerRadius: 2).fill(item.category.color)
                                                            .frame(width: g.size.width * CGFloat(item.pct), height: 4)
                                                    }
                                                }.frame(height: 4)
                                            }
                                            
                                            Text("$\(NSDecimalNumber(decimal: item.amount).intValue)")
                                                .font(VoyaraTypography.labelSmall).foregroundColor(VoyaraColors.text)
                                        }
                                        .padding(VoyaraTheme.spacing12)
                                        .background(VoyaraColors.surface)
                                        .cornerRadius(VoyaraTheme.mediumRadius)
                                    }
                                }
                                .padding(.horizontal, VoyaraTheme.spacing24)
                            }
                        }
                        
                        // Per-Trip Budget
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                            SectionHeader(title: "Trip Budgets").padding(.horizontal, VoyaraTheme.spacing24)
                            ForEach(tripViewModel.trips) { trip in
                                let spent = tripViewModel.expensesForTrip(trip).reduce(0) { $0 + $1.amount }
                                let pct = trip.budget > 0 ? Double(truncating: (spent / trip.budget) as NSNumber) : 0
                                
                                VoyaraCard {
                                    VStack(spacing: VoyaraTheme.spacing12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(trip.title).font(VoyaraTypography.headlineSmall).foregroundColor(VoyaraColors.text)
                                                Text(trip.destination).font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                                            }
                                            Spacer()
                                            Text("$\(NSDecimalNumber(decimal: spent).intValue) / $\(NSDecimalNumber(decimal: trip.budget).intValue)")
                                                .font(VoyaraTypography.labelSmall).foregroundColor(pct > 0.9 ? VoyaraColors.error : VoyaraColors.text)
                                        }
                                        GeometryReader { g in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3).fill(VoyaraColors.surfaceVariant).frame(height: 6)
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(pct > 0.9 ? VoyaraColors.error : (pct > 0.7 ? VoyaraColors.warning : VoyaraColors.primary))
                                                    .frame(width: g.size.width * min(CGFloat(pct), 1.0), height: 6)
                                            }
                                        }.frame(height: 6)
                                    }
                                }
                                .padding(.horizontal, VoyaraTheme.spacing24)
                            }
                        }
                        
                        // Recent Expenses
                        VStack(alignment: .leading, spacing: VoyaraTheme.spacing12) {
                            SectionHeader(title: "Recent Expenses").padding(.horizontal, VoyaraTheme.spacing24)
                            ForEach(tripViewModel.trips.flatMap { $0.expenses }.sorted(by: { $0.date > $1.date }).prefix(10)) { expense in
                                if let trip = tripViewModel.trips.first(where: { $0.id == expense.tripId }) {
                                    ExpenseRow(expense: expense, onDelete: {
                                        tripViewModel.deleteExpense(expense, from: trip)
                                    }).padding(.horizontal, VoyaraTheme.spacing24)
                                } else {
                                    ExpenseRow(expense: expense, onDelete: {}).padding(.horizontal, VoyaraTheme.spacing24)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, VoyaraTheme.spacing16)
                }
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCurrencyConverter = true }) {
                        Image(systemName: "dollarsign.arrow.circlepath")
                            .foregroundColor(VoyaraColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCurrencyConverter) {
                CurrencyConverterView()
            }
        }
    }
    
    private func budgetStat(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: VoyaraTheme.spacing8) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading) {
                Text(label).font(VoyaraTypography.captionSmall).foregroundColor(VoyaraColors.textSecondary)
                Text(value).font(VoyaraTypography.labelMedium).foregroundColor(VoyaraColors.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VoyaraTheme.spacing12)
        .background(color.opacity(0.08))
        .cornerRadius(VoyaraTheme.smallRadius)
    }
    
    private func categoryBreakdown() -> [(category: ExpenseCategory, amount: Decimal, pct: Double)] {
        var totals: [ExpenseCategory: Decimal] = [:]
        for e in tripViewModel.trips.flatMap({ $0.expenses }) {
            if let cat = ExpenseCategory(rawValue: e.category) { totals[cat, default: 0] += e.amount }
        }
        let maxAmount = totals.values.max() ?? 1
        return totals.map { (category: $0.key, amount: $0.value, pct: Double(truncating: ($0.value / maxAmount) as NSNumber)) }
            .sorted { $0.amount > $1.amount }
    }
}
