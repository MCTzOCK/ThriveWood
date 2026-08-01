import SwiftUI

// MARK: - Semantic values

public enum BentoTone: String, CaseIterable, Identifiable, Sendable {
    case neutral
    case accent
    case success
    case warning
    case danger
    case info
    case yellow
    case green
    case blue
    case pink

    public var id: Self { self }
}

public enum BentoSpace: Sendable {
    case none
    case xxs
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl
}

public enum BentoRadius: Sendable {
    case small
    case medium
    case large
    case extraLarge
    case pill
}

public enum BentoTextStyle: CaseIterable, Identifiable, Sendable {
    case display
    case title1
    case title2
    case title3
    case metric
    case headline
    case body
    case bodyStrong
    case callout
    case caption
    case overline

    public var id: Self { self }
}

// MARK: - Color construction

public extension Color {
    init(bentoHex hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Color tokens

public struct BentoColors: Sendable {
    public let background: Color
    public let onBackground: Color

    public let surface: Color
    public let surfaceSecondary: Color
    public let onSurface: Color
    public let onSurfaceMuted: Color

    public let outline: Color
    public let outlineSubtle: Color

    public let accent: Color
    public let onAccent: Color

    public let success: Color
    public let onSuccess: Color

    public let warning: Color
    public let onWarning: Color

    public let danger: Color
    public let onDanger: Color

    public let info: Color
    public let onInfo: Color

    public let tileYellow: Color
    public let tileGreen: Color
    public let tileBlue: Color
    public let tilePink: Color
    public let onTile: Color

    public let chrome: Color
    public let onChrome: Color

    public let focus: Color
    public let disabled: Color

    public init(
        background: Color,
        onBackground: Color,
        surface: Color,
        surfaceSecondary: Color,
        onSurface: Color,
        onSurfaceMuted: Color,
        outline: Color,
        outlineSubtle: Color,
        accent: Color,
        onAccent: Color,
        success: Color,
        onSuccess: Color,
        warning: Color,
        onWarning: Color,
        danger: Color,
        onDanger: Color,
        info: Color,
        onInfo: Color,
        tileYellow: Color,
        tileGreen: Color,
        tileBlue: Color,
        tilePink: Color,
        onTile: Color,
        chrome: Color,
        onChrome: Color,
        focus: Color,
        disabled: Color
    ) {
        self.background = background
        self.onBackground = onBackground
        self.surface = surface
        self.surfaceSecondary = surfaceSecondary
        self.onSurface = onSurface
        self.onSurfaceMuted = onSurfaceMuted
        self.outline = outline
        self.outlineSubtle = outlineSubtle
        self.accent = accent
        self.onAccent = onAccent
        self.success = success
        self.onSuccess = onSuccess
        self.warning = warning
        self.onWarning = onWarning
        self.danger = danger
        self.onDanger = onDanger
        self.info = info
        self.onInfo = onInfo
        self.tileYellow = tileYellow
        self.tileGreen = tileGreen
        self.tileBlue = tileBlue
        self.tilePink = tilePink
        self.onTile = onTile
        self.chrome = chrome
        self.onChrome = onChrome
        self.focus = focus
        self.disabled = disabled
    }

    public func fill(for tone: BentoTone) -> Color {
        switch tone {
        case .neutral:
            surfaceSecondary
        case .accent:
            accent
        case .success:
            success
        case .warning:
            warning
        case .danger:
            danger
        case .info:
            info
        case .yellow:
            tileYellow
        case .green:
            tileGreen
        case .blue:
            tileBlue
        case .pink:
            tilePink
        }
    }

    public func foreground(for tone: BentoTone) -> Color {
        switch tone {
        case .neutral:
            onSurface
        case .accent:
            onAccent
        case .success:
            onSuccess
        case .warning:
            onWarning
        case .danger:
            onDanger
        case .info:
            onInfo
        case .yellow, .green, .blue, .pink:
            onTile
        }
    }

    public func replacing(
        outline: Color? = nil,
        outlineSubtle: Color? = nil,
        accent: Color? = nil,
        onAccent: Color? = nil,
        success: Color? = nil,
        onSuccess: Color? = nil,
        warning: Color? = nil,
        onWarning: Color? = nil,
        danger: Color? = nil,
        onDanger: Color? = nil,
        info: Color? = nil,
        onInfo: Color? = nil,
        tileYellow: Color? = nil,
        tileGreen: Color? = nil,
        tileBlue: Color? = nil,
        tilePink: Color? = nil,
        onTile: Color? = nil,
        focus: Color? = nil
    ) -> BentoColors {
        BentoColors(
            background: background,
            onBackground: onBackground,
            surface: surface,
            surfaceSecondary: surfaceSecondary,
            onSurface: onSurface,
            onSurfaceMuted: onSurfaceMuted,
            outline: outline ?? self.outline,
            outlineSubtle: outlineSubtle ?? self.outlineSubtle,
            accent: accent ?? self.accent,
            onAccent: onAccent ?? self.onAccent,
            success: success ?? self.success,
            onSuccess: onSuccess ?? self.onSuccess,
            warning: warning ?? self.warning,
            onWarning: onWarning ?? self.onWarning,
            danger: danger ?? self.danger,
            onDanger: onDanger ?? self.onDanger,
            info: info ?? self.info,
            onInfo: onInfo ?? self.onInfo,
            tileYellow: tileYellow ?? self.tileYellow,
            tileGreen: tileGreen ?? self.tileGreen,
            tileBlue: tileBlue ?? self.tileBlue,
            tilePink: tilePink ?? self.tilePink,
            onTile: onTile ?? self.onTile,
            chrome: chrome,
            onChrome: onChrome,
            focus: focus ?? self.focus,
            disabled: disabled
        )
    }
}

// MARK: - Spacing and dimensions

public struct BentoSpacing: Sendable {
    public let xxs: CGFloat
    public let xs: CGFloat
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat
    public let xxl: CGFloat

    public init(
        xxs: CGFloat = 4,
        xs: CGFloat = 8,
        sm: CGFloat = 12,
        md: CGFloat = 16,
        lg: CGFloat = 20,
        xl: CGFloat = 28,
        xxl: CGFloat = 40
    ) {
        self.xxs = xxs
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }

    public static let standard = BentoSpacing()

    public func value(_ token: BentoSpace) -> CGFloat {
        switch token {
        case .none:
            0
        case .xxs:
            xxs
        case .xs:
            xs
        case .sm:
            sm
        case .md:
            md
        case .lg:
            lg
        case .xl:
            xl
        case .xxl:
            xxl
        }
    }
}

public struct BentoRadii: Sendable {
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat
    public let extraLarge: CGFloat
    public let pill: CGFloat

    public init(
        small: CGFloat = 10,
        medium: CGFloat = 15,
        large: CGFloat = 21,
        extraLarge: CGFloat = 28,
        pill: CGFloat = 999
    ) {
        self.small = small
        self.medium = medium
        self.large = large
        self.extraLarge = extraLarge
        self.pill = pill
    }

    public static let standard = BentoRadii()

    public func value(_ token: BentoRadius) -> CGFloat {
        switch token {
        case .small:
            small
        case .medium:
            medium
        case .large:
            large
        case .extraLarge:
            extraLarge
        case .pill:
            pill
        }
    }
}

public struct BentoBorders: Sendable {
    public let thin: CGFloat
    public let regular: CGFloat
    public let strong: CGFloat

    public init(
        thin: CGFloat = 1,
        regular: CGFloat = 2,
        strong: CGFloat = 3
    ) {
        self.thin = thin
        self.regular = regular
        self.strong = strong
    }

    public static let standard = BentoBorders()
    public static let highContrast = BentoBorders(
        thin: 1.5,
        regular: 2.5,
        strong: 4
    )
}

public struct BentoSizing: Sendable {
    public let controlSmall: CGFloat
    public let controlMedium: CGFloat
    public let controlLarge: CGFloat
    public let minimumTouchTarget: CGFloat
    public let tabBarHeight: CGFloat
    public let contentMaxWidth: CGFloat

    public init(
        controlSmall: CGFloat = 38,
        controlMedium: CGFloat = 48,
        controlLarge: CGFloat = 56,
        minimumTouchTarget: CGFloat = 44,
        tabBarHeight: CGFloat = 76,
        contentMaxWidth: CGFloat = 760
    ) {
        self.controlSmall = controlSmall
        self.controlMedium = controlMedium
        self.controlLarge = controlLarge
        self.minimumTouchTarget = minimumTouchTarget
        self.tabBarHeight = tabBarHeight
        self.contentMaxWidth = contentMaxWidth
    }

    public static let standard = BentoSizing()
}

public struct BentoMotion: Sendable {
    public let fastDuration: Double
    public let regularDuration: Double
    public let slowDuration: Double
    public let springResponse: Double
    public let springDamping: Double

    public init(
        fastDuration: Double = 0.16,
        regularDuration: Double = 0.28,
        slowDuration: Double = 0.45,
        springResponse: Double = 0.34,
        springDamping: Double = 0.78
    ) {
        self.fastDuration = fastDuration
        self.regularDuration = regularDuration
        self.slowDuration = slowDuration
        self.springResponse = springResponse
        self.springDamping = springDamping
    }

    public static let standard = BentoMotion()

    public var fast: Animation {
        .easeOut(duration: fastDuration)
    }

    public var regular: Animation {
        .easeInOut(duration: regularDuration)
    }

    public var snappy: Animation {
        .spring(
            response: springResponse,
            dampingFraction: springDamping
        )
    }
}

// MARK: - Typography

public enum BentoFontDesign: Sendable {
    case system
    case rounded
    case monospaced
    case serif

    fileprivate var swiftUIDesign: Font.Design {
        switch self {
        case .system:
            .default
        case .rounded:
            .rounded
        case .monospaced:
            .monospaced
        case .serif:
            .serif
        }
    }
}

public struct BentoTypography: Sendable {
    public let displayFontName: String?
    public let bodyFontName: String?
    public let displayDesign: BentoFontDesign
    public let bodyDesign: BentoFontDesign
    public let usesMonospacedDigits: Bool

    public init(
        displayFontName: String? = nil,
        bodyFontName: String? = nil,
        displayDesign: BentoFontDesign = .monospaced,
        bodyDesign: BentoFontDesign = .monospaced,
        usesMonospacedDigits: Bool = true
    ) {
        self.displayFontName = displayFontName
        self.bodyFontName = bodyFontName
        self.displayDesign = displayDesign
        self.bodyDesign = bodyDesign
        self.usesMonospacedDigits = usesMonospacedDigits
    }

    public static let typewriter = BentoTypography()

    public func font(for style: BentoTextStyle) -> Font {
        let spec = specification(for: style)
        let customName = spec.isDisplay ? displayFontName : bodyFontName
        let design = spec.isDisplay ? displayDesign : bodyDesign

        if let customName {
            return Font
                .custom(
                    customName,
                    size: spec.customSize,
                    relativeTo: spec.relativeTo
                )
                .weight(spec.weight)
        }

        return .system(
            spec.relativeTo,
            design: design.swiftUIDesign,
            weight: spec.weight
        )
    }

    fileprivate func tracking(for style: BentoTextStyle) -> CGFloat {
        specification(for: style).tracking
    }

    fileprivate func lineSpacing(for style: BentoTextStyle) -> CGFloat {
        specification(for: style).lineSpacing
    }

    private func specification(for style: BentoTextStyle) -> FontSpecification {
        switch style {
        case .display:
            FontSpecification(
                customSize: 40,
                relativeTo: .largeTitle,
                weight: .black,
                tracking: -1,
                lineSpacing: 2,
                isDisplay: true
            )

        case .title1:
            FontSpecification(
                customSize: 32,
                relativeTo: .title,
                weight: .bold,
                tracking: -0.7,
                lineSpacing: 2,
                isDisplay: true
            )

        case .title2:
            FontSpecification(
                customSize: 24,
                relativeTo: .title2,
                weight: .bold,
                tracking: -0.4,
                lineSpacing: 2,
                isDisplay: true
            )

        case .title3:
            FontSpecification(
                customSize: 20,
                relativeTo: .title3,
                weight: .bold,
                tracking: -0.2,
                lineSpacing: 2,
                isDisplay: true
            )

        case .metric:
            FontSpecification(
                customSize: 36,
                relativeTo: .largeTitle,
                weight: .black,
                tracking: -1,
                lineSpacing: 0,
                isDisplay: true
            )

        case .headline:
            FontSpecification(
                customSize: 17,
                relativeTo: .headline,
                weight: .bold,
                tracking: -0.1,
                lineSpacing: 3,
                isDisplay: false
            )

        case .body:
            FontSpecification(
                customSize: 16,
                relativeTo: .body,
                weight: .regular,
                tracking: 0,
                lineSpacing: 4,
                isDisplay: false
            )

        case .bodyStrong:
            FontSpecification(
                customSize: 16,
                relativeTo: .body,
                weight: .bold,
                tracking: 0,
                lineSpacing: 4,
                isDisplay: false
            )

        case .callout:
            FontSpecification(
                customSize: 14,
                relativeTo: .callout,
                weight: .medium,
                tracking: 0,
                lineSpacing: 3,
                isDisplay: false
            )

        case .caption:
            FontSpecification(
                customSize: 12,
                relativeTo: .caption,
                weight: .medium,
                tracking: 0.1,
                lineSpacing: 2,
                isDisplay: false
            )

        case .overline:
            FontSpecification(
                customSize: 11,
                relativeTo: .caption2,
                weight: .bold,
                tracking: 1,
                lineSpacing: 2,
                isDisplay: false
            )
        }
    }
}

private struct FontSpecification {
    let customSize: CGFloat
    let relativeTo: Font.TextStyle
    let weight: Font.Weight
    let tracking: CGFloat
    let lineSpacing: CGFloat
    let isDisplay: Bool
}

// MARK: - Theme

public struct BentoTheme: Sendable {
    public let name: String
    public let colors: BentoColors
    public let typography: BentoTypography
    public let spacing: BentoSpacing
    public let radii: BentoRadii
    public let borders: BentoBorders
    public let sizing: BentoSizing
    public let motion: BentoMotion

    public init(
        name: String,
        colors: BentoColors,
        typography: BentoTypography = .typewriter,
        spacing: BentoSpacing = .standard,
        radii: BentoRadii = .standard,
        borders: BentoBorders = .standard,
        sizing: BentoSizing = .standard,
        motion: BentoMotion = .standard
    ) {
        self.name = name
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radii = radii
        self.borders = borders
        self.sizing = sizing
        self.motion = motion
    }
}

private extension BentoColors {
    static var paperLight: BentoColors {
        BentoColors(
            background: Color(bentoHex: 0x111310),
            onBackground: Color(bentoHex: 0xFAF8F0),
            surface: Color(bentoHex: 0xF5F3EC),
            surfaceSecondary: Color(bentoHex: 0xE7E5DD),
            onSurface: Color(bentoHex: 0x171915),
            onSurfaceMuted: Color(bentoHex: 0x5E615A),
            outline: Color(bentoHex: 0x20231E),
            outlineSubtle: Color(bentoHex: 0xC9C9BF),
            accent: Color(bentoHex: 0x9DDD54),
            onAccent: Color(bentoHex: 0x132408),
            success: Color(bentoHex: 0xBEE8A5),
            onSuccess: Color(bentoHex: 0x17350E),
            warning: Color(bentoHex: 0xFFD36A),
            onWarning: Color(bentoHex: 0x3B2800),
            danger: Color(bentoHex: 0xFFAAA7),
            onDanger: Color(bentoHex: 0x420B09),
            info: Color(bentoHex: 0xA8DCF7),
            onInfo: Color(bentoHex: 0x082C40),
            tileYellow: Color(bentoHex: 0xF5C75B),
            tileGreen: Color(bentoHex: 0xDCEFCC),
            tileBlue: Color(bentoHex: 0xBEE1F7),
            tilePink: Color(bentoHex: 0xF2C6DA),
            onTile: Color(bentoHex: 0x171915),
            chrome: Color(bentoHex: 0x101210),
            onChrome: Color(bentoHex: 0xFAF8F0),
            focus: Color(bentoHex: 0x2668FF),
            disabled: Color(bentoHex: 0xBDBDB5)
        )
    }

    static var paperDark: BentoColors {
        BentoColors(
            background: Color(bentoHex: 0x090B09),
            onBackground: Color(bentoHex: 0xF8F5EB),
            surface: Color(bentoHex: 0x1A1D19),
            surfaceSecondary: Color(bentoHex: 0x282C26),
            onSurface: Color(bentoHex: 0xF8F5EB),
            onSurfaceMuted: Color(bentoHex: 0xB9BBB2),
            outline: Color(bentoHex: 0xF0EEE5),
            outlineSubtle: Color(bentoHex: 0x43483F),
            accent: Color(bentoHex: 0xA9E663),
            onAccent: Color(bentoHex: 0x122408),
            success: Color(bentoHex: 0x2F6334),
            onSuccess: Color(bentoHex: 0xF3FFED),
            warning: Color(bentoHex: 0x755B16),
            onWarning: Color(bentoHex: 0xFFF7D8),
            danger: Color(bentoHex: 0x783A39),
            onDanger: Color(bentoHex: 0xFFF0EF),
            info: Color(bentoHex: 0x275B75),
            onInfo: Color(bentoHex: 0xECF9FF),
            tileYellow: Color(bentoHex: 0x5D4B18),
            tileGreen: Color(bentoHex: 0x294A27),
            tileBlue: Color(bentoHex: 0x244C61),
            tilePink: Color(bentoHex: 0x5B3347),
            onTile: Color(bentoHex: 0xFFF9EE),
            chrome: Color(bentoHex: 0x050605),
            onChrome: Color(bentoHex: 0xFAF8F0),
            focus: Color(bentoHex: 0x75A2FF),
            disabled: Color(bentoHex: 0x62665E)
        )
    }
}

public extension BentoTheme {
    static let paperLight = BentoTheme(
        name: "Paper Light",
        colors: .paperLight
    )

    static let paperDark = BentoTheme(
        name: "Paper Dark",
        colors: .paperDark
    )

    static let paperHighContrastLight = BentoTheme(
        name: "Paper High Contrast Light",
        colors: BentoColors.paperLight.replacing(
            outline: .black,
            outlineSubtle: Color(bentoHex: 0x62645E),
            focus: Color(bentoHex: 0x0048E5)
        ),
        borders: .highContrast
    )

    static let paperHighContrastDark = BentoTheme(
        name: "Paper High Contrast Dark",
        colors: BentoColors.paperDark.replacing(
            outline: .white,
            outlineSubtle: Color(bentoHex: 0xB9BDB4),
            focus: Color(bentoHex: 0x9CBBFF)
        ),
        borders: .highContrast
    )

    static let berryLight = BentoTheme(
        name: "Berry Light",
        colors: BentoColors.paperLight.replacing(
            accent: Color(bentoHex: 0xF064A5),
            onAccent: Color(bentoHex: 0x3B0921),
            info: Color(bentoHex: 0xC8B7FF),
            onInfo: Color(bentoHex: 0x21134D),
            tileYellow: Color(bentoHex: 0xFFD786),
            tileGreen: Color(bentoHex: 0xC7E8D0),
            tileBlue: Color(bentoHex: 0xC8D6FF),
            tilePink: Color(bentoHex: 0xF4B8D4),
            focus: Color(bentoHex: 0xA32868)
        )
    )

    static let berryDark = BentoTheme(
        name: "Berry Dark",
        colors: BentoColors.paperDark.replacing(
            accent: Color(bentoHex: 0xFF80B9),
            onAccent: Color(bentoHex: 0x310417),
            info: Color(bentoHex: 0x56468A),
            onInfo: Color(bentoHex: 0xF8F3FF),
            tileYellow: Color(bentoHex: 0x654B18),
            tileGreen: Color(bentoHex: 0x244D39),
            tileBlue: Color(bentoHex: 0x35466F),
            tilePink: Color(bentoHex: 0x6D3450),
            focus: Color(bentoHex: 0xFF9BC9)
        )
    )

    static let berryHighContrastLight = BentoTheme(
        name: "Berry High Contrast Light",
        colors: BentoTheme.berryLight.colors.replacing(
            outline: .black,
            outlineSubtle: Color(bentoHex: 0x62645E)
        ),
        borders: .highContrast
    )

    static let berryHighContrastDark = BentoTheme(
        name: "Berry High Contrast Dark",
        colors: BentoTheme.berryDark.colors.replacing(
            outline: .white,
            outlineSubtle: Color(bentoHex: 0xB9BDB4)
        ),
        borders: .highContrast
    )
}

// MARK: - Theme families

public struct BentoThemeFamily: Sendable {
    public let name: String
    public let light: BentoTheme
    public let dark: BentoTheme
    public let highContrastLight: BentoTheme
    public let highContrastDark: BentoTheme

    public init(
        name: String,
        light: BentoTheme,
        dark: BentoTheme,
        highContrastLight: BentoTheme,
        highContrastDark: BentoTheme
    ) {
        self.name = name
        self.light = light
        self.dark = dark
        self.highContrastLight = highContrastLight
        self.highContrastDark = highContrastDark
    }

    public func theme(
        for colorScheme: ColorScheme,
        increasedContrast: Bool
    ) -> BentoTheme {
        switch (colorScheme, increasedContrast) {
        case (.light, false):
            light
        case (.dark, false):
            dark
        case (.light, true):
            highContrastLight
        case (.dark, true):
            highContrastDark
        @unknown default:
            light
        }
    }
}

public extension BentoThemeFamily {
    static let paper = BentoThemeFamily(
        name: "Paper",
        light: .paperLight,
        dark: .paperDark,
        highContrastLight: .paperHighContrastLight,
        highContrastDark: .paperHighContrastDark
    )

    static let berry = BentoThemeFamily(
        name: "Berry",
        light: .berryLight,
        dark: .berryDark,
        highContrastLight: .berryHighContrastLight,
        highContrastDark: .berryHighContrastDark
    )
}

public enum BentoThemeMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: Self { self }

    fileprivate var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

public enum BentoContrastMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case standard
    case increased

    public var id: Self { self }
}

// MARK: - Theme environment

private struct BentoThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = BentoTheme.paperLight
}

public extension EnvironmentValues {
    var bentoTheme: BentoTheme {
        get { self[BentoThemeEnvironmentKey.self] }
        set { self[BentoThemeEnvironmentKey.self] = newValue }
    }
}

public struct BentoThemeHost<Content: View>: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.legibilityWeight) private var legibilityWeight

    private let family: BentoThemeFamily
    private let mode: BentoThemeMode
    private let contrastMode: BentoContrastMode
    private let content: Content

    public init(
        family: BentoThemeFamily = .paper,
        mode: BentoThemeMode = .system,
        contrastMode: BentoContrastMode = .system,
        @ViewBuilder content: () -> Content
    ) {
        self.family = family
        self.mode = mode
        self.contrastMode = contrastMode
        self.content = content()
    }

    public var body: some View {
        let resolvedScheme = mode.preferredColorScheme ?? systemColorScheme

        let increasedContrast: Bool = {
            switch contrastMode {
            case .system:
                legibilityWeight != .regular
            case .standard:
                false
            case .increased:
                true
            }
        }()

        let resolvedTheme = family.theme(
            for: resolvedScheme,
            increasedContrast: increasedContrast
        )

        content
            .environment(\.bentoTheme, resolvedTheme)
            .tint(resolvedTheme.colors.accent)
            .preferredColorScheme(mode.preferredColorScheme)
    }
}

// MARK: - Typography modifier

private struct BentoMonospacedDigitsModifier: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.monospacedDigit()
        } else {
            content
        }
    }
}

private struct BentoOptionalForegroundModifier: ViewModifier {
    let color: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let color {
            content.foregroundStyle(color)
        } else {
            content
        }
    }
}

private struct BentoTextStyleModifier: ViewModifier {
    @Environment(\.bentoTheme) private var theme

    let style: BentoTextStyle
    let color: Color?

    func body(content: Content) -> some View {
        content
            .font(theme.typography.font(for: style))
            .tracking(theme.typography.tracking(for: style))
            .lineSpacing(theme.typography.lineSpacing(for: style))
            .modifier(
                BentoMonospacedDigitsModifier(
                    enabled: theme.typography.usesMonospacedDigits
                )
            )
            .modifier(BentoOptionalForegroundModifier(color: color))
    }
}

public extension View {
    func bentoTheme(_ theme: BentoTheme) -> some View {
        environment(\.bentoTheme, theme)
            .tint(theme.colors.accent)
    }

    func bentoTextStyle(
        _ style: BentoTextStyle,
        color: Color? = nil
    ) -> some View {
        modifier(
            BentoTextStyleModifier(
                style: style,
                color: color
            )
        )
    }
}

public struct BentoText: View {
    private let text: Text
    private let style: BentoTextStyle
    private let color: Color?

    public init(
        _ key: LocalizedStringKey,
        style: BentoTextStyle = .body,
        color: Color? = nil
    ) {
        self.text = Text(key)
        self.style = style
        self.color = color
    }

    public init(
        verbatim value: String,
        style: BentoTextStyle = .body,
        color: Color? = nil
    ) {
        self.text = Text(verbatim: value)
        self.style = style
        self.color = color
    }

    public init(
        _ text: Text,
        style: BentoTextStyle = .body,
        color: Color? = nil
    ) {
        self.text = text
        self.style = style
        self.color = color
    }

    public var body: some View {
        text.bentoTextStyle(style, color: color)
    }
}
