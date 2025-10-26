import SwiftUI

/// Showcase view demonstrating enhanced Liquid Glass compliance
/// Use this to test and validate your Liquid Glass implementations
struct LiquidGlassShowcaseView: View {
    @State private var selectedTab = 0
    @State private var toggleState = false
    @State private var sliderValue: Double = 0.5
    @State private var isPressed = false
    @Namespace private var morphingNamespace
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // MARK: - Basic Glass Effects
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Glass Effects")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LiquidGlassContainer(spacing: 20.0) {
                            HStack(spacing: 16) {
                                // Regular glass
                                VStack {
                                    Text("Regular")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Rectangle()
                                        .frame(width: 80, height: 60)
                                        .liquidGlass()
                                }
                                
                                // Tinted glass
                                VStack {
                                    Text("Tinted")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Rectangle()
                                        .frame(width: 80, height: 60)
                                        .liquidGlass(
                                            tint: .accentColor,
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                }
                                
                                // Interactive glass
                                VStack {
                                    Text("Interactive")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Rectangle()
                                        .frame(width: 80, height: 60)
                                        .liquidGlass(
                                            tint: .green,
                                            in: RoundedRectangle(cornerRadius: 12),
                                            isInteractive: true
                                        )
                                        .scaleEffect(isPressed ? 0.95 : 1.0)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                isPressed.toggle()
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.easeInOut(duration: 0.1)) {
                                                    isPressed = false
                                                }
                                            }
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // MARK: - Button Styles
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Button Styles")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LiquidGlassContainer(spacing: 24.0) {
                            VStack(spacing: 12) {
                                // Standard liquid glass button
                                Button("Standard Glass Button") {
                                    print("Standard button tapped")
                                }
                                .buttonStyle(.liquidGlass())
                                
                                // Prominent glass button
                                Button("Prominent Glass Button") {
                                    print("Prominent button tapped")
                                }
                                .buttonStyle(.liquidGlassProminent)
                                
                                // Custom shaped button
                                Button("Custom Shape") {
                                    print("Custom button tapped")
                                }
                                .buttonStyle(.liquidGlass(
                                    tint: .orange,
                                    shape: RoundedRectangle(cornerRadius: 20)
                                ))
                            }
                            .padding()
                        }
                    }
                    
                    // MARK: - Tab Bar Showcase
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tab Bar with Glass Container")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LiquidGlassContainer(spacing: 20.0) {
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    Button("Tab \(index + 1)") {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedTab = index
                                        }
                                    }
                                    .foregroundColor(selectedTab == index ? .primary : .secondary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .liquidGlass(
                                        tint: selectedTab == index ? .accentColor : nil,
                                        isInteractive: true
                                    )
                                }
                            }
                            .padding()
                            .liquidGlass(in: Capsule())
                        }
                    }
                    
                    // MARK: - Morphing Effects
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Morphing and Animation")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LiquidGlassContainer(spacing: 30.0) {
                            HStack(spacing: 20) {
                                // Static element
                                VStack {
                                    Text("Static")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Circle()
                                        .frame(width: 60, height: 60)
                                        .liquidGlass(
                                            tint: .blue,
                                            in: Circle()
                                        )
                                }
                                
                                // Morphing element
                                VStack {
                                    Text("Tap to Toggle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            toggleState.toggle()
                                        }
                                    }) {
                                        if toggleState {
                                            RoundedRectangle(cornerRadius: 8)
                                                .frame(width: 60, height: 60)
                                                .liquidGlass(
                                                    tint: .green,
                                                    in: RoundedRectangle(cornerRadius: 8),
                                                    isInteractive: true
                                                )
                                        } else {
                                            Circle()
                                                .frame(width: 60, height: 60)
                                                .liquidGlass(
                                                    tint: .red,
                                                    in: Circle(),
                                                    isInteractive: true
                                                )
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // MARK: - Controls Showcase  
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Glass Controls")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 20) {
                            // Slider with glass track
                            VStack(spacing: 8) {
                                Text("Glass Slider")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $sliderValue, in: 0...1)
                                    .liquidGlass(
                                        in: Capsule(),
                                        isInteractive: true
                                    )
                                    .padding()
                            }
                            .liquidGlass(
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .padding(.horizontal)
                            
                            // Toggle with glass background
                            HStack {
                                Text("Glass Toggle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $toggleState)
                                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            }
                            .padding()
                            .liquidGlass(
                                in: RoundedRectangle(cornerRadius: 16),
                                isInteractive: true
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // MARK: - Status Indicators
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Status Indicators")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LiquidGlassContainer(spacing: 16.0) {
                            HStack(spacing: 12) {
                                // Success indicator
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .liquidGlass(
                                    tint: .green,
                                    in: Capsule(),
                                    isInteractive: true
                                )
                                
                                // Warning indicator
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 8, height: 8)
                                    Text("Warning")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .liquidGlass(
                                    tint: .orange,
                                    in: Capsule(),
                                    isInteractive: true
                                )
                                
                                // Error indicator
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("Error")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .liquidGlass(
                                    tint: .red,
                                    in: Capsule(),
                                    isInteractive: true
                                )
                            }
                            .padding()
                        }
                    }
                    
                    // Bottom padding
                    Color.clear.frame(height: 50)
                }
                .padding(.top)
            }
            .navigationTitle("Liquid Glass Showcase")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark) // Liquid Glass looks best on dark backgrounds
    }
}

// MARK: - Preview

struct LiquidGlassShowcaseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LiquidGlassShowcaseView()
                .previewDisplayName("Dark Mode")
                .preferredColorScheme(.dark)
            
            LiquidGlassShowcaseView()
                .previewDisplayName("Light Mode")
                .preferredColorScheme(.light)
                
            LiquidGlassShowcaseView()
                .previewDisplayName("Reduced Transparency")
                .environment(\.accessibilityReduceTransparency, true)
        }
    }
}