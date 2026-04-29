import Foundation

extension String {
    /// Simple compatibility shim so views that expect `category.icon` compile.
    var icon: String { self }
}
