//
//  PDFService.swift
//  ThriveWood
//
//  Created by Ben Siebert on 14.05.26.
//
import SwiftUI
import PDFKit
import UIKit
import Combine
import Foundation

// MARK: - PDFService

final class PDFService: ObservableObject {
    
    public static let shared = PDFService()
    private init() {}
    
    // MARK: - Page Layout Constants (DIN A4)
    
    private enum Layout {
        static let pageWidth: CGFloat = 595.2     // A4 @ 72dpi
        static let pageHeight: CGFloat = 841.8
        static let marginH: CGFloat = 40
        static let marginTop: CGFloat = 48
        static let marginBottom: CGFloat = 56
        static let contentWidth: CGFloat = pageWidth - (marginH * 2)
        
        static let headerHeight: CGFloat = 110
        static let footerHeight: CGFloat = 30
        
        static let cardCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 14
        static let cardSpacing: CGFloat = 14
        
        static let sectionSpacing: CGFloat = 18
        
        static let rowHeight: CGFloat = 26
        static let tableHeaderHeight: CGFloat = 28
        static let checkboxSize: CGFloat = 14
    }
    
    // MARK: - Colors
    
    private enum Palette {
        static let accent = UIColor(red: 0.27, green: 0.55, blue: 0.96, alpha: 1.0)
        static let textPrimary = UIColor(white: 0.12, alpha: 1.0)
        static let textSecondary = UIColor(white: 0.42, alpha: 1.0)
        static let textTertiary = UIColor(white: 0.62, alpha: 1.0)
        static let cardBackground = UIColor(white: 0.97, alpha: 1.0)
        static let cardBorder = UIColor(white: 0.88, alpha: 1.0)
        static let tableHeader = UIColor(white: 0.93, alpha: 1.0)
        static let tableRowAlt = UIColor(white: 0.985, alpha: 1.0)
        static let tableBorder = UIColor(white: 0.85, alpha: 1.0)
        static let badgeBackground = UIColor(red: 0.27, green: 0.55, blue: 0.96, alpha: 0.12)
        static let divider = UIColor(white: 0.88, alpha: 1.0)
    }
    
    // MARK: - Fonts
    
    private enum Fonts {
        static let title = UIFont.systemFont(ofSize: 26, weight: .bold)
        static let subtitle = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let sectionTitle = UIFont.systemFont(ofSize: 11, weight: .semibold)
        static let exerciseTitle = UIFont.systemFont(ofSize: 15, weight: .semibold)
        static let exerciseSubtitle = UIFont.systemFont(ofSize: 11, weight: .regular)
        static let body = UIFont.systemFont(ofSize: 11, weight: .regular)
        static let bodyBold = UIFont.systemFont(ofSize: 11, weight: .semibold)
        static let small = UIFont.systemFont(ofSize: 9, weight: .regular)
        static let smallBold = UIFont.systemFont(ofSize: 9, weight: .semibold)
        static let badge = UIFont.systemFont(ofSize: 9, weight: .semibold)
        static let footer = UIFont.systemFont(ofSize: 9, weight: .regular)
        static let tableHeader = UIFont.systemFont(ofSize: 10, weight: .semibold)
        static let tableCell = UIFont.systemFont(ofSize: 11, weight: .regular)
    }
    
    // MARK: - Public API
    
    /// Erstellt ein PDF für das angegebene Workout und gibt die URL zur temporären Datei zurück.
    @discardableResult
    public func createPDF(for workout: Workout) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(
            bounds: pageRect,
            format: makeFormat(for: workout)
        )
        
        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }
        let dateString = Self.dateFormatter.string(from: .now)
        
        let data = renderer.pdfData { ctx in
            var pageIndex = 0
            var cursorY: CGFloat = 0
            
            // Start first page
            ctx.beginPage()
            pageIndex += 1
            drawHeader(in: pageRect, workout: workout, dateString: dateString)
            drawFooter(in: pageRect, pageNumber: pageIndex)
            cursorY = Layout.marginTop + Layout.headerHeight + Layout.sectionSpacing
            
            // Workout Summary Card
            let summaryHeight = workoutSummaryHeight(for: workout)
            if cursorY + summaryHeight > pageRect.height - Layout.marginBottom - Layout.footerHeight {
                ctx.beginPage()
                pageIndex += 1
                drawCompactHeader(in: pageRect, workout: workout)
                drawFooter(in: pageRect, pageNumber: pageIndex)
                cursorY = Layout.marginTop + 50
            }
            drawWorkoutSummary(workout: workout, at: cursorY)
            cursorY += summaryHeight + Layout.sectionSpacing
            
            // Section Title: Exercises
            if !sortedExercises.isEmpty {
                if cursorY + 30 > pageRect.height - Layout.marginBottom - Layout.footerHeight {
                    ctx.beginPage()
                    pageIndex += 1
                    drawCompactHeader(in: pageRect, workout: workout)
                    drawFooter(in: pageRect, pageNumber: pageIndex)
                    cursorY = Layout.marginTop + 50
                }
                drawSectionTitle("ÜBUNGEN", at: cursorY)
                cursorY += 22
            }
            
            // Render each exercise
            for (idx, we) in sortedExercises.enumerated() {
                let cardHeight = exerciseCardHeight(for: we)
                let remaining = pageRect.height - Layout.marginBottom - Layout.footerHeight - cursorY
                
                if cardHeight > remaining {
                    // Page break
                    ctx.beginPage()
                    pageIndex += 1
                    drawCompactHeader(in: pageRect, workout: workout)
                    drawFooter(in: pageRect, pageNumber: pageIndex)
                    cursorY = Layout.marginTop + 50
                }
                
                drawExerciseCard(we, index: idx + 1, at: cursorY)
                cursorY += cardHeight + Layout.cardSpacing
            }
            
            // Notes section
            let notesHeight: CGFloat = 120
            let remaining = pageRect.height - Layout.marginBottom - Layout.footerHeight - cursorY
            if notesHeight > remaining {
                ctx.beginPage()
                pageIndex += 1
                drawCompactHeader(in: pageRect, workout: workout)
                drawFooter(in: pageRect, pageNumber: pageIndex)
                cursorY = Layout.marginTop + 50
            }
            drawNotesSection(at: cursorY)
        }
        
        // Save to temp
        let filename = sanitizeFilename(workout.name) + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("PDFService: Failed to write PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - Format / Metadata
    
    private func makeFormat(for workout: Workout) -> UIGraphicsPDFRendererFormat {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: workout.name,
            kCGPDFContextAuthor as String: "ThriveWood",
            kCGPDFContextCreator as String: "ThriveWood iOS",
            kCGPDFContextSubject as String: "Workout Plan",
            kCGPDFContextKeywords as String: "Workout, Training, Fitness, ThriveWood"
        ] as [String: Any]
        return format
    }
    
    // MARK: - Header / Footer
    
    private func drawHeader(in pageRect: CGRect, workout: Workout, dateString: String) {
        let accent = uiColor(from: workout.color.rawValue) ?? Palette.accent
        
        // Accent stripe
        let stripeRect = CGRect(
            x: Layout.marginH,
            y: Layout.marginTop,
            width: 4,
            height: 64
        )
        let stripePath = UIBezierPath(roundedRect: stripeRect, cornerRadius: 2)
        accent.setFill()
        stripePath.fill()
        
        // Title
        let titleX = Layout.marginH + 16
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Palette.textPrimary
        ]
        let titleRect = CGRect(
            x: titleX,
            y: Layout.marginTop + 4,
            width: Layout.contentWidth - 16,
            height: 32
        )
        (workout.name as NSString).draw(in: titleRect, withAttributes: titleAttrs)
        
        // Subtitle (details or "Workout Plan")
        let subtitle = workout.details.isEmpty ? "Trainingsplan" : workout.details
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.subtitle,
            .foregroundColor: Palette.textSecondary
        ]
        let subRect = CGRect(
            x: titleX,
            y: Layout.marginTop + 38,
            width: Layout.contentWidth - 16,
            height: 18
        )
        (subtitle as NSString).draw(in: subRect, withAttributes: subAttrs)
        
        // Meta info row (date, duration, exercises)
        let metaY = Layout.marginTop + 64
        drawMetaBadge(
            text: dateString,
            icon: "📅",
            at: CGPoint(x: titleX, y: metaY)
        )
        let exCount = workout.exercises.count
        drawMetaBadge(
            text: "\(exCount) \(exCount == 1 ? "Übung" : "Übungen")",
            icon: "🏋",
            at: CGPoint(x: titleX + 140, y: metaY)
        )
        drawMetaBadge(
            text: "~\(workout.estimatedDurationMinutes) min",
            icon: "⏱",
            at: CGPoint(x: titleX + 280, y: metaY)
        )
        
        // Divider line
        let dividerY = Layout.marginTop + Layout.headerHeight - 6
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: Layout.marginH, y: dividerY))
        divider.addLine(to: CGPoint(x: Layout.pageWidth - Layout.marginH, y: dividerY))
        Palette.divider.setStroke()
        divider.lineWidth = 0.5
        divider.stroke()
    }
    
    private func drawCompactHeader(in pageRect: CGRect, workout: Workout) {
        let accent = uiColor(from: workout.color.rawValue) ?? Palette.accent
        
        // Small accent dot
        let dotRect = CGRect(x: Layout.marginH, y: Layout.marginTop + 4, width: 8, height: 8)
        accent.setFill()
        UIBezierPath(ovalIn: dotRect).fill()
        
        // Workout name (smaller)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: Palette.textSecondary
        ]
        let rect = CGRect(
            x: Layout.marginH + 16,
            y: Layout.marginTop,
            width: Layout.contentWidth - 16,
            height: 18
        )
        (workout.name as NSString).draw(in: rect, withAttributes: attrs)
        
        // "Fortsetzung" hint
        let cont = "— Fortsetzung"
        let contAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: Palette.textTertiary
        ]
        let nameWidth = (workout.name as NSString).size(withAttributes: attrs).width
        let contRect = CGRect(
            x: Layout.marginH + 16 + nameWidth + 6,
            y: Layout.marginTop + 2,
            width: 120,
            height: 16
        )
        (cont as NSString).draw(in: contRect, withAttributes: contAttrs)
        
        // Divider
        let dividerY = Layout.marginTop + 28
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: Layout.marginH, y: dividerY))
        divider.addLine(to: CGPoint(x: Layout.pageWidth - Layout.marginH, y: dividerY))
        Palette.divider.setStroke()
        divider.lineWidth = 0.5
        divider.stroke()
    }
    
    private func drawFooter(in pageRect: CGRect, pageNumber: Int) {
        let footerY = pageRect.height - Layout.marginBottom + 16
        
        // Divider
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: Layout.marginH, y: footerY - 8))
        divider.addLine(to: CGPoint(x: Layout.pageWidth - Layout.marginH, y: footerY - 8))
        Palette.divider.setStroke()
        divider.lineWidth = 0.5
        divider.stroke()
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.footer,
            .foregroundColor: Palette.textTertiary
        ]
        
        // Left: branding
        let leftText = "ThriveWood · Workout Plan"
        (leftText as NSString).draw(
            at: CGPoint(x: Layout.marginH, y: footerY),
            withAttributes: attrs
        )
        
        // Right: page number
        let rightText = "Seite \(pageNumber)"
        let size = (rightText as NSString).size(withAttributes: attrs)
        (rightText as NSString).draw(
            at: CGPoint(x: Layout.pageWidth - Layout.marginH - size.width, y: footerY),
            withAttributes: attrs
        )
    }
    
    // MARK: - Meta Badge
    
    private func drawMetaBadge(text: String, icon: String, at point: CGPoint) {
        let combined = "\(icon)  \(text)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: Palette.textSecondary
        ]
        (combined as NSString).draw(at: point, withAttributes: attrs)
    }
    
    // MARK: - Section Title
    
    private func drawSectionTitle(_ title: String, at y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.sectionTitle,
            .foregroundColor: Palette.textTertiary,
            .kern: 1.2
        ]
        let rect = CGRect(x: Layout.marginH, y: y, width: Layout.contentWidth, height: 16)
        (title as NSString).draw(in: rect, withAttributes: attrs)
    }
    
    // MARK: - Workout Summary
    
    private func workoutSummaryHeight(for workout: Workout) -> CGFloat {
        let hasDetails = !workout.details.isEmpty
        let muscleGroupsHeight: CGFloat = 28
        let baseHeight: CGFloat = 70
        return baseHeight + muscleGroupsHeight + (hasDetails ? 24 : 0)
    }
    
    private func drawWorkoutSummary(workout: Workout, at y: CGFloat) {
        let height = workoutSummaryHeight(for: workout)
        let rect = CGRect(
            x: Layout.marginH,
            y: y,
            width: Layout.contentWidth,
            height: height
        )
        drawCard(in: rect)
        
        let innerX = rect.minX + Layout.cardPadding
        var innerY = rect.minY + Layout.cardPadding
        
        // Title
        let title = "ÜBERSICHT"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.sectionTitle,
            .foregroundColor: Palette.textTertiary,
            .kern: 1.2
        ]
        (title as NSString).draw(at: CGPoint(x: innerX, y: innerY), withAttributes: titleAttrs)
        innerY += 18
        
        // Stats row: total sets, est. duration, target muscle groups count
        let totalSets = workout.exercises.reduce(0) { $0 + $1.targetSets }
        let allMuscles = Set(workout.exercises.flatMap { $0.exercise?.primaryMuscleGroups ?? [] })
        
        let cellWidth = (Layout.contentWidth - 2 * Layout.cardPadding) / 3
        drawStat(title: "Sätze gesamt", value: "\(totalSets)", at: CGPoint(x: innerX, y: innerY), width: cellWidth)
        drawStat(title: "Dauer", value: "~\(workout.estimatedDurationMinutes) min", at: CGPoint(x: innerX + cellWidth, y: innerY), width: cellWidth)
        drawStat(title: "Muskelgruppen", value: "\(allMuscles.count)", at: CGPoint(x: innerX + cellWidth * 2, y: innerY), width: cellWidth)
        innerY += 44
        
        // Muscle groups badges
        if !allMuscles.isEmpty {
            let sortedMuscles = allMuscles.map { $0.label.capitalized }.sorted()
            drawBadgeRow(items: sortedMuscles, at: CGPoint(x: innerX, y: innerY), maxWidth: Layout.contentWidth - 2 * Layout.cardPadding)
        }
    }
    
    private func drawStat(title: String, value: String, at point: CGPoint, width: CGFloat) {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.small,
            .foregroundColor: Palette.textTertiary
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: Palette.textPrimary
        ]
        (title as NSString).draw(at: point, withAttributes: titleAttrs)
        (value as NSString).draw(
            at: CGPoint(x: point.x, y: point.y + 12),
            withAttributes: valueAttrs
        )
    }
    
    // MARK: - Exercise Card
    
    private func exerciseCardHeight(for we: WorkoutExercise) -> CGFloat {
        let headerHeight: CGFloat = 56
        let notesHeight: CGFloat = we.notes.isEmpty ? 0 : 22
        let targetsHeight: CGFloat = 24
        let tableHeaderH = Layout.tableHeaderHeight
        let tableRowsH = CGFloat(we.targetSets) * Layout.rowHeight
        let padding: CGFloat = Layout.cardPadding * 2
        return headerHeight + targetsHeight + notesHeight + tableHeaderH + tableRowsH + padding
    }
    
    private func drawExerciseCard(_ we: WorkoutExercise, index: Int, at y: CGFloat) {
        let height = exerciseCardHeight(for: we)
        let rect = CGRect(
            x: Layout.marginH,
            y: y,
            width: Layout.contentWidth,
            height: height
        )
        drawCard(in: rect)
        
        let innerX = rect.minX + Layout.cardPadding
        var innerY = rect.minY + Layout.cardPadding
        let innerWidth = rect.width - 2 * Layout.cardPadding
        
        // Header: Index badge + Name + Category
        let badgeSize: CGFloat = 28
        let badgeRect = CGRect(x: innerX, y: innerY, width: badgeSize, height: badgeSize)
        Palette.badgeBackground.setFill()
        UIBezierPath(roundedRect: badgeRect, cornerRadius: 6).fill()
        
        let badgeText = "\(index)"
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: Palette.accent
        ]
        let badgeTextSize = (badgeText as NSString).size(withAttributes: badgeAttrs)
        (badgeText as NSString).draw(
            at: CGPoint(
                x: badgeRect.midX - badgeTextSize.width / 2,
                y: badgeRect.midY - badgeTextSize.height / 2
            ),
            withAttributes: badgeAttrs
        )
        
        let nameX = innerX + badgeSize + 10
        let nameWidth = innerWidth - badgeSize - 10
        
        let name = we.exercise?.name ?? "Unbekannte Übung"
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.exerciseTitle,
            .foregroundColor: Palette.textPrimary
        ]
        (name as NSString).draw(
            in: CGRect(x: nameX, y: innerY, width: nameWidth, height: 18),
            withAttributes: nameAttrs
        )
        
        // Subtitle: muscle groups
        let primary = we.exercise?.primaryMuscleGroups.map { $0.label.capitalized } ?? []
        let subtitleText = primary.isEmpty ? (we.exercise?.category.id.capitalized ?? "") : primary.joined(separator: " · ")
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.exerciseSubtitle,
            .foregroundColor: Palette.textSecondary
        ]
        (subtitleText as NSString).draw(
            in: CGRect(x: nameX, y: innerY + 18, width: nameWidth, height: 14),
            withAttributes: subtitleAttrs
        )
        
        innerY += 44
        
        // Targets row
        var targetParts: [String] = []
        if let reps = we.targetReps { targetParts.append("\(reps) Wdh.") }
        if let weight = we.targetWeight, weight > 0 { targetParts.append("\(weight.clean) kg") }
        if let dur = we.targetDurationSeconds { targetParts.append(formatDuration(dur)) }
        if let dist = we.targetDistanceMeters {
            targetParts.append(String(format: "%.2f km", dist / 1000))
        }
        targetParts.append("Pause: \(we.restSeconds)s")
        
        let targetsText = "Ziel: " + targetParts.joined(separator: "  ·  ")
        let targetsAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Palette.textSecondary
        ]
        (targetsText as NSString).draw(
            at: CGPoint(x: innerX, y: innerY),
            withAttributes: targetsAttrs
        )
        innerY += 22
        
        // Notes (optional)
        if !we.notes.isEmpty {
            let notesText = "Notiz: \(we.notes)"
            let notesAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: Palette.textSecondary
            ]
            (notesText as NSString).draw(
                in: CGRect(x: innerX, y: innerY, width: innerWidth, height: 16),
                withAttributes: notesAttrs
            )
            innerY += 20
        }
        
        // Set tracking table
        drawSetTable(
            for: we,
            at: CGRect(x: innerX, y: innerY, width: innerWidth, height: rect.maxY - innerY - Layout.cardPadding)
        )
    }
    
    // MARK: - Set Tracking Table
    
    private func drawSetTable(for we: WorkoutExercise, at rect: CGRect) {
        let trackingType = we.exercise?.trackingType ?? .repsWeight
        let columns = tableColumns(for: trackingType)
        
        // Compute column widths
        let totalWidth = rect.width
        let checkboxColW: CGFloat = 36
        let setColW: CGFloat = 40
        let remainingW = totalWidth - checkboxColW - setColW
        let dynamicColW = remainingW / CGFloat(columns.count)
        
        var xOffsets: [CGFloat] = [rect.minX]
        xOffsets.append(rect.minX + checkboxColW)
        xOffsets.append(rect.minX + checkboxColW + setColW)
        for i in 1..<columns.count {
            xOffsets.append(rect.minX + checkboxColW + setColW + dynamicColW * CGFloat(i))
        }
        xOffsets.append(rect.maxX)
        
        // Header row
        let headerRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: Layout.tableHeaderHeight)
        Palette.tableHeader.setFill()
        UIBezierPath(roundedRect: headerRect, cornerRadius: 4).fill()
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tableHeader,
            .foregroundColor: Palette.textPrimary
        ]
        
        // ✓ column header
        drawCenteredText("✓", in: CGRect(x: xOffsets[0], y: headerRect.minY, width: checkboxColW, height: Layout.tableHeaderHeight), attrs: headerAttrs)
        // Set column header
        drawCenteredText("Satz", in: CGRect(x: xOffsets[1], y: headerRect.minY, width: setColW, height: Layout.tableHeaderHeight), attrs: headerAttrs)
        
        for (i, col) in columns.enumerated() {
            let colRect = CGRect(
                x: xOffsets[2 + i],
                y: headerRect.minY,
                width: dynamicColW,
                height: Layout.tableHeaderHeight
            )
            drawCenteredText(col.title, in: colRect, attrs: headerAttrs)
        }
        
        // Body rows
        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tableCell,
            .foregroundColor: Palette.textPrimary
        ]
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tableCell,
            .foregroundColor: Palette.textTertiary
        ]
        
        for setIdx in 0..<we.targetSets {
            let rowY = rect.minY + Layout.tableHeaderHeight + CGFloat(setIdx) * Layout.rowHeight
            let rowRect = CGRect(x: rect.minX, y: rowY, width: rect.width, height: Layout.rowHeight)
            
            // Alternating row background
            if setIdx % 2 == 1 {
                Palette.tableRowAlt.setFill()
                UIBezierPath(rect: rowRect).fill()
            }
            
            // Checkbox
            let cbRect = CGRect(
                x: xOffsets[0] + (checkboxColW - Layout.checkboxSize) / 2,
                y: rowY + (Layout.rowHeight - Layout.checkboxSize) / 2,
                width: Layout.checkboxSize,
                height: Layout.checkboxSize
            )
            let cbPath = UIBezierPath(roundedRect: cbRect, cornerRadius: 3)
            Palette.tableBorder.setStroke()
            cbPath.lineWidth = 1
            cbPath.stroke()
            
            // Set number
            drawCenteredText(
                "\(setIdx + 1)",
                in: CGRect(x: xOffsets[1], y: rowY, width: setColW, height: Layout.rowHeight),
                attrs: cellAttrs
            )
            
            // Target value cells
            for (i, col) in columns.enumerated() {
                let cellRect = CGRect(
                    x: xOffsets[2 + i],
                    y: rowY,
                    width: dynamicColW,
                    height: Layout.rowHeight
                )
                let text = col.value(we)
                let useAttrs = text.isEmpty ? placeholderAttrs : cellAttrs
                let displayText = ""
                drawCenteredText(displayText, in: cellRect, attrs: useAttrs)
            }
            
            // Row bottom divider
            if setIdx < we.targetSets - 1 {
                let line = UIBezierPath()
                line.move(to: CGPoint(x: rect.minX + 4, y: rowRect.maxY))
                line.addLine(to: CGPoint(x: rect.maxX - 4, y: rowRect.maxY))
                Palette.tableBorder.setStroke()
                line.lineWidth = 0.4
                line.stroke()
            }
        }
        
        // Table outline
        let tableHeight = Layout.tableHeaderHeight + CGFloat(we.targetSets) * Layout.rowHeight
        let outline = UIBezierPath(
            roundedRect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: tableHeight),
            cornerRadius: 4
        )
        Palette.tableBorder.setStroke()
        outline.lineWidth = 0.6
        outline.stroke()
        
        // Vertical separators
        for i in 1..<(2 + columns.count) {
            let line = UIBezierPath()
            line.move(to: CGPoint(x: xOffsets[i], y: rect.minY + 4))
            line.addLine(to: CGPoint(x: xOffsets[i], y: rect.minY + tableHeight - 4))
            Palette.tableBorder.setStroke()
            line.lineWidth = 0.4
            line.stroke()
        }
    }
    
    private struct TableColumn {
        let title: String
        let value: (WorkoutExercise) -> String
    }
    
    private func tableColumns(for type: ExerciseTrackingType) -> [TableColumn] {
        switch type {
        case .repsWeight:
            return [
                TableColumn(title: "Gewicht (kg)") { we in
                    guard let w = we.targetWeight, w > 0 else { return "" }
                    return w.clean
                },
                TableColumn(title: "Wdh.") { we in
                    guard let r = we.targetReps else { return "" }
                    return "\(r)"
                },
                TableColumn(title: "RPE") { _ in "" }
            ]
        case .reps:
            return [
                TableColumn(title: "Wdh.") { we in
                    guard let r = we.targetReps else { return "" }
                    return "\(r)"
                },
                TableColumn(title: "Notiz") { _ in "" }
            ]
        case .duration:
            return [
                TableColumn(title: "Dauer") { we in
                    guard let d = we.targetDurationSeconds else { return "" }
                    return self.formatDuration(d)
                },
                TableColumn(title: "Notiz") { _ in "" }
            ]
        case .distanceDuration:
            return [
                TableColumn(title: "Distanz (km)") { we in
                    guard let d = we.targetDistanceMeters else { return "" }
                    return String(format: "%.2f", d / 1000)
                },
                TableColumn(title: "Dauer") { we in
                    guard let d = we.targetDurationSeconds else { return "" }
                    return self.formatDuration(d)
                }
            ]
        }
    }
    
    // MARK: - Notes Section
    
    private func drawNotesSection(at y: CGFloat) {
        drawSectionTitle("NOTIZEN", at: y)
        
        let lineY = y + 28
        let lineCount = 5
        let lineSpacing: CGFloat = 18
        
        Palette.tableBorder.setStroke()
        for i in 0..<lineCount {
            let path = UIBezierPath()
            let yPos = lineY + CGFloat(i) * lineSpacing
            path.move(to: CGPoint(x: Layout.marginH, y: yPos))
            path.addLine(to: CGPoint(x: Layout.pageWidth - Layout.marginH, y: yPos))
            path.lineWidth = 0.5
            path.stroke()
        }
    }
    
    // MARK: - Drawing Helpers
    
    private func drawCard(in rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: Layout.cardCornerRadius)
        Palette.cardBackground.setFill()
        path.fill()
        Palette.cardBorder.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    private func drawBadgeRow(items: [String], at point: CGPoint, maxWidth: CGFloat) {
        var x = point.x
        let y = point.y
        let badgeFont = Fonts.badge
        let hPadding: CGFloat = 8
        let vPadding: CGFloat = 4
        let spacing: CGFloat = 6
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: Palette.accent
        ]
        
        for item in items {
            let size = (item as NSString).size(withAttributes: attrs)
            let badgeWidth = size.width + hPadding * 2
            let badgeHeight = size.height + vPadding * 2
            
            // Wrap if needed
            if x + badgeWidth > point.x + maxWidth {
                break // simple truncation; could be extended to wrap
            }
            
            let badgeRect = CGRect(x: x, y: y, width: badgeWidth, height: badgeHeight)
            Palette.badgeBackground.setFill()
            UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeHeight / 2).fill()
            
            (item as NSString).draw(
                at: CGPoint(x: x + hPadding, y: y + vPadding),
                withAttributes: attrs
            )
            
            x += badgeWidth + spacing
        }
    }
    
    private func drawCenteredText(_ text: String, in rect: CGRect, attrs: [NSAttributedString.Key: Any]) {
        let size = (text as NSString).size(withAttributes: attrs)
        let point = CGPoint(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2
        )
        (text as NSString).draw(at: point, withAttributes: attrs)
    }
    
    // MARK: - Utilities
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }()
    
    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
    
    private func sanitizeFilename(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        return cleaned.isEmpty ? "Workout" : cleaned
    }
    
    private func uiColor(from value: String) -> UIColor? {
        // Try hex first
        var hex = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        if hex.count == 6, let rgb = UInt32(hex, radix: 16) {
            let r = CGFloat((rgb >> 16) & 0xFF) / 255
            let g = CGFloat((rgb >> 8) & 0xFF) / 255
            let b = CGFloat(rgb & 0xFF) / 255
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }
        // Fallback: try HabitColor raw value mapping
        switch value.lowercased() {
        case "red": return .systemRed
        case "orange": return .systemOrange
        case "yellow": return .systemYellow
        case "green": return .systemGreen
        case "mint": return .systemMint
        case "teal": return .systemTeal
        case "cyan": return .systemCyan
        case "blue": return .systemBlue
        case "indigo": return .systemIndigo
        case "purple": return .systemPurple
        case "pink": return .systemPink
        case "brown": return .systemBrown
        default: return nil
        }
    }
}
