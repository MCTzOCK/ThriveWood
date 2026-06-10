//
//  AchievementDefinitions.swift
//  ThriveWood
//

import SwiftUI

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case habit, workout, forest, muscle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .habit: "Gewohnheiten"
        case .workout: "Workouts"
        case .forest: "Wald"
        case .muscle: "Muskeln"
        }
    }

    var icon: String {
        switch self {
        case .habit: "checklist"
        case .workout: "dumbbell.fill"
        case .forest: "leaf.fill"
        case .muscle: "figure.strengthtraining.traditional"
        }
    }

    var color: Color {
        switch self {
        case .habit: .green
        case .workout: .blue
        case .forest: .mint
        case .muscle: .orange
        }
    }
}

enum AchievementDefinition: String, Codable, CaseIterable, Identifiable {

    // MARK: - Habits
    case firstHabit
    case habitCreator5
    case habitCreator10
    case firstCompletion
    case habitsAllInOneDay5
    case habitsAllInOneDay10
    case habitsAllInOneDayAll
    case streak3
    case streak7
    case streak14
    case streak30
    case streak60
    case streak100
    case streak180
    case streak365
    case points10
    case points50
    case points100
    case points250
    case points500
    case points1000
    case points2500
    case points5000
    case measurableGoal100
    case measurableGoal500
    case measurableGoal1000
    case pointsSingleDay10
    case pointsSingleDay20
    case pointsSingleDay30

    // MARK: - Workouts
    case firstWorkout
    case workouts5
    case workouts10
    case workouts25
    case workouts50
    case workouts75
    case workouts100
    case workouts200
    case workoutDuration30
    case workoutDuration60
    case workoutDuration90
    case firstPR
    case prCount5
    case prCount15
    case prCount30
    case totalVolume1000
    case totalVolume10000
    case totalVolume50000
    case totalVolume100000
    case totalVolume250000
    case workout3DaysRow
    case workout7DaysRow
    case firstCardio
    case firstStrength
    case setsCompleted100
    case setsCompleted500
    case setsCompleted1000

    // MARK: - Forest
    case firstTree
    case trees3
    case trees5
    case trees10
    case trees15
    case trees25
    case trees40
    case firstOak
    case firstPine
    case firstBirch
    case firstMaple
    case firstWillow
    case firstCherry
    case firstSequoia
    case firstBonsai
    case treeGrowthSapling
    case treeGrowthYoung
    case treeGrowthMature
    case treeGrowthAncient
    case treesAncient2
    case treesAncient5
    case forestCoverage25
    case forestCoverage50
    case forestCoverage75
    case pointsSpent50
    case pointsSpent200
    case pointsSpent500

    // MARK: - Muscle
    case muscleBronze
    case muscleBronze5
    case muscleBronze10
    case muscleSilver
    case muscleSilver5
    case muscleSilver10
    case muscleGold
    case muscleGold5
    case muscleGold10
    case musclePlatinum
    case musclePlatinum3
    case muscleDiamond
    case muscleChampion
    case muscleLegend
    case muscleUpperBodyBronze
    case muscleLowerBodyBronze
    case muscleCoreBronze
    case muscleBackBronze
    case muscleFirstSet
    case muscleSetsTotal100
    case muscleSetsTotal500

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstHabit: "Erster Schritt"
        case .habitCreator5: "Gewohnheits-Designer"
        case .habitCreator10: "Lebensarchitekt"
        case .firstCompletion: "Erste Erledigung"
        case .habitsAllInOneDay5: "Fokus-Veteran"
        case .habitsAllInOneDay10: "Produktivitäts-Meister"
        case .habitsAllInOneDayAll: "Perfekter Tag"
        case .streak3: "Dreier-Serie"
        case .streak7: "Wochen-Streak"
        case .streak14: "Zwei Wochen am Stück"
        case .streak30: "Monats-Streak"
        case .streak60: "Zwei Monate Disziplin"
        case .streak100: "Hundert-Tage-Streak"
        case .streak180: "Halbjahr-Streak"
        case .streak365: "Ganzjahres-Streak"
        case .points10: "Erste Punkte"
        case .points50: "Punkte-Sammler"
        case .points100: "Punkte-Jäger"
        case .points250: "Punkte-Profi"
        case .points500: "Punkte-Meister"
        case .points1000: "Punkte-Legende"
        case .points2500: "Punkte-Diamant"
        case .points5000: "Punkte-Gottheit"
        case .measurableGoal100: "Zahlen-Mensch"
        case .measurableGoal500: "Zielstrebig"
        case .measurableGoal1000: "Mess-Meister"
        case .pointsSingleDay10: "Produktiver Tag"
        case .pointsSingleDay20: "Super-Tag"
        case .pointsSingleDay30: "Ultimativer Tag"

        case .firstWorkout: "Erstes Workout"
        case .workouts5: "Fünf Workouts"
        case .workouts10: "Zehn Workouts"
        case .workouts25: "Trainings-Routine"
        case .workouts50: "Halbes Hundert"
        case .workouts75: "Dreiviertel-Hundert"
        case .workouts100: "Hundert Workouts"
        case .workouts200: "Doppel-Hundert"
        case .workoutDuration30: "Halbe Stunde"
        case .workoutDuration60: "Vollstunde"
        case .workoutDuration90: "Marathon-Session"
        case .firstPR: "Erster Rekord"
        case .prCount5: "Fünf Rekorde"
        case .prCount15: "Fünfzehn Rekorde"
        case .prCount30: "Dreißig Rekorde"
        case .totalVolume1000: "Erste Tonne"
        case .totalVolume10000: "Zehn Tonnen"
        case .totalVolume50000: "Fünfzig Tonnen"
        case .totalVolume100000: "Hundert Tonnen"
        case .totalVolume250000: "Viertel Megatonne"
        case .workout3DaysRow: "Drei Tage in Folge"
        case .workout7DaysRow: "Trainings-Woche"
        case .firstCardio: "Cardio-Einsteiger"
        case .firstStrength: "Kraft-Einsteiger"
        case .setsCompleted100: "Hundert Sätze"
        case .setsCompleted500: "Fünfhundert Sätze"
        case .setsCompleted1000: "Tausend Sätze"

        case .firstTree: "Erster Baum"
        case .trees3: "Kleines Wäldchen"
        case .trees5: "Wachsender Wald"
        case .trees10: "Zehn Bäume"
        case .trees15: "Grüne Oase"
        case .trees25: "Waldgebiet"
        case .trees40: "Dichter Wald"
        case .firstOak: "Eichen-Pflanzer"
        case .firstPine: "Kiefern-Pflanzer"
        case .firstBirch: "Birken-Pflanzer"
        case .firstMaple: "Ahorn-Pflanzer"
        case .firstWillow: "Weiden-Pflanzer"
        case .firstCherry: "Kirsch-Pflanzer"
        case .firstSequoia: "Mammutbaum-Pflanzer"
        case .firstBonsai: "Bonsai-Meister"
        case .treeGrowthSapling: "Grünes Leben"
        case .treeGrowthYoung: "Junger Baum"
        case .treeGrowthMature: "Ausgewachsen"
        case .treeGrowthAncient: "Uralter Baum"
        case .treesAncient2: "Alter Hase"
        case .treesAncient5: "Wald-Weiser"
        case .forestCoverage25: "Viertel Wald"
        case .forestCoverage50: "Halber Wald"
        case .forestCoverage75: "Dreiviertel Wald"
        case .pointsSpent50: "Erste Investitionen"
        case .pointsSpent200: "Großzügiger Gärtner"
        case .pointsSpent500: "Wald-Benefaktor"

        case .muscleBronze: "Erste Medaille"
        case .muscleBronze5: "Bronze-Kollektion"
        case .muscleBronze10: "Bronze-Vollausstattung"
        case .muscleSilver: "Silber-Rang"
        case .muscleSilver5: "Silber-Kollektion"
        case .muscleSilver10: "Silber-Vollausstattung"
        case .muscleGold: "Gold-Rang"
        case .muscleGold5: "Gold-Kollektion"
        case .muscleGold10: "Gold-Vollausstattung"
        case .musclePlatinum: "Platin-Status"
        case .musclePlatinum3: "Platin-Kollektion"
        case .muscleDiamond: "Diamant-Rang"
        case .muscleChampion: "Champion-Rang"
        case .muscleLegend: "Legenden-Status"
        case .muscleUpperBodyBronze: "Oberkörper-Bronze"
        case .muscleLowerBodyBronze: "Unterkörper-Bronze"
        case .muscleCoreBronze: "Rumpf-Bronze"
        case .muscleBackBronze: "Rücken-Bronze"
        case .muscleFirstSet: "Erster Satz"
        case .muscleSetsTotal100: "Hundert Muskel-Sätze"
        case .muscleSetsTotal500: "Fünfhundert Muskel-Sätze"
        }
    }

    var description: String {
        switch self {
        case .firstHabit: "Erstelle dein erstes Habit"
        case .habitCreator5: "Erstelle 5 verschiedene Habits"
        case .habitCreator10: "Erstelle 10 verschiedene Habits"
        case .firstCompletion: "Schließe ein Habit zum ersten Mal ab"
        case .habitsAllInOneDay5: "Schließe 5 Habits an einem Tag ab"
        case .habitsAllInOneDay10: "Schließe 10 Habits an einem Tag ab"
        case .habitsAllInOneDayAll: "Schließe alle fälligen Habits an einem Tag ab"
        case .streak3: "Erreiche einen 3-Tage-Streak"
        case .streak7: "Erreiche einen 7-Tage-Streak"
        case .streak14: "Erreiche einen 14-Tage-Streak"
        case .streak30: "Erreiche einen 30-Tage-Streak"
        case .streak60: "Erreiche einen 60-Tage-Streak"
        case .streak100: "Erreiche einen 100-Tage-Streak"
        case .streak180: "Erreiche einen 180-Tage-Streak"
        case .streak365: "Erreiche einen 365-Tage-Streak"
        case .points10: "Verdiene insgesamt 10 Punkte"
        case .points50: "Verdiene insgesamt 50 Punkte"
        case .points100: "Verdiene insgesamt 100 Punkte"
        case .points250: "Verdiene insgesamt 250 Punkte"
        case .points500: "Verdiene insgesamt 500 Punkte"
        case .points1000: "Verdiene insgesamt 1.000 Punkte"
        case .points2500: "Verdiene insgesamt 2.500 Punkte"
        case .points5000: "Verdiene insgesamt 5.000 Punkte"
        case .measurableGoal100: "Erreiche 100% bei einem messbaren Habit"
        case .measurableGoal500: "Sammle 500 messbare Fortschritte"
        case .measurableGoal1000: "Sammle 1.000 messbare Fortschritte"
        case .pointsSingleDay10: "Verdiene 10 Punkte an einem Tag"
        case .pointsSingleDay20: "Verdiene 20 Punkte an einem Tag"
        case .pointsSingleDay30: "Verdiene 30 Punkte an einem Tag"

        case .firstWorkout: "Schließe dein erstes Workout ab"
        case .workouts5: "Schließe 5 Workouts ab"
        case .workouts10: "Schließe 10 Workouts ab"
        case .workouts25: "Schließe 25 Workouts ab"
        case .workouts50: "Schließe 50 Workouts ab"
        case .workouts75: "Schließe 75 Workouts ab"
        case .workouts100: "Schließe 100 Workouts ab"
        case .workouts200: "Schließe 200 Workouts ab"
        case .workoutDuration30: "Trainiere 30 Minuten in einer Session"
        case .workoutDuration60: "Trainiere 60 Minuten in einer Session"
        case .workoutDuration90: "Trainiere 90 Minuten in einer Session"
        case .firstPR: "Stelle deinen ersten Rekord auf"
        case .prCount5: "Stelle 5 Rekorde auf"
        case .prCount15: "Stelle 15 Rekorde auf"
        case .prCount30: "Stelle 30 Rekorde auf"
        case .totalVolume1000: "Hebe insgesamt 1.000 kg Volumen"
        case .totalVolume10000: "Hebe insgesamt 10.000 kg Volumen"
        case .totalVolume50000: "Hebe insgesamt 50.000 kg Volumen"
        case .totalVolume100000: "Hebe insgesamt 100.000 kg Volumen"
        case .totalVolume250000: "Hebe insgesamt 250.000 kg Volumen"
        case .workout3DaysRow: "Trainiere 3 Tage in Folge"
        case .workout7DaysRow: "Trainiere 7 Tage in Folge"
        case .firstCardio: "Absolviere ein Cardio-Workout"
        case .firstStrength: "Absolviere ein Kraft-Workout"
        case .setsCompleted100: "Schließe 100 Sätze ab"
        case .setsCompleted500: "Schließe 500 Sätze ab"
        case .setsCompleted1000: "Schließe 1.000 Sätze ab"

        case .firstTree: "Pflanze deinen ersten Baum"
        case .trees3: "Pflanze 3 Bäume"
        case .trees5: "Pflanze 5 Bäume"
        case .trees10: "Pflanze 10 Bäume"
        case .trees15: "Pflanze 15 Bäume"
        case .trees25: "Pflanze 25 Bäume"
        case .trees40: "Pflanze 40 Bäume"
        case .firstOak: "Pflanze eine Eiche"
        case .firstPine: "Pflanze eine Kiefer"
        case .firstBirch: "Pflanze eine Birke"
        case .firstMaple: "Pflanze einen Ahorn"
        case .firstWillow: "Pflanze eine Weide"
        case .firstCherry: "Pflanze eine Kirsche"
        case .firstSequoia: "Pflanze einen Mammutbaum"
        case .firstBonsai: "Pflanze einen Bonsai"
        case .treeGrowthSapling: "Bringe einen Baum auf Stufe 'Setzling'"
        case .treeGrowthYoung: "Bringe einen Baum auf Stufe 'Jung'"
        case .treeGrowthMature: "Bringe einen Baum auf Stufe 'Ausgewachsen'"
        case .treeGrowthAncient: "Bringe einen Baum auf Stufe 'Uralt'"
        case .treesAncient2: "Bringe 2 Bäume auf Stufe 'Uralt'"
        case .treesAncient5: "Bringe 5 Bäume auf Stufe 'Uralt'"
        case .forestCoverage25: "Fülle 25% deines Waldes"
        case .forestCoverage50: "Fülle 50% deines Waldes"
        case .forestCoverage75: "Fülle 75% deines Waldes"
        case .pointsSpent50: "Gib 50 Punkte im Wald aus"
        case .pointsSpent200: "Gib 200 Punkte im Wald aus"
        case .pointsSpent500: "Gib 500 Punkte im Wald aus"

        case .muscleBronze: "Bringe einen Muskel auf Bronze"
        case .muscleBronze5: "Bringe 5 Muskeln auf Bronze"
        case .muscleBronze10: "Bringe 10 Muskeln auf Bronze"
        case .muscleSilver: "Bringe einen Muskel auf Silber"
        case .muscleSilver5: "Bringe 5 Muskeln auf Silber"
        case .muscleSilver10: "Bringe 10 Muskeln auf Silber"
        case .muscleGold: "Bringe einen Muskel auf Gold"
        case .muscleGold5: "Bringe 5 Muskeln auf Gold"
        case .muscleGold10: "Bringe 10 Muskeln auf Gold"
        case .musclePlatinum: "Bringe einen Muskel auf Platin"
        case .musclePlatinum3: "Bringe 3 Muskeln auf Platin"
        case .muscleDiamond: "Bringe einen Muskel auf Diamant"
        case .muscleChampion: "Bringe einen Muskel auf Champion"
        case .muscleLegend: "Bringe einen Muskel auf Legende"
        case .muscleUpperBodyBronze: "Bringe einen Oberkörpermuskel auf Bronze"
        case .muscleLowerBodyBronze: "Bringe einen Unterkörpermuskel auf Bronze"
        case .muscleCoreBronze: "Bringe Bauch auf Bronze"
        case .muscleBackBronze: "Bringe einen Rückenmuskel auf Bronze"
        case .muscleFirstSet: "Schließe deinen ersten Muskel-Satz ab"
        case .muscleSetsTotal100: "Sammle 100 Muskel-Sätze"
        case .muscleSetsTotal500: "Sammle 500 Muskel-Sätze"
        }
    }

    var icon: String {
        switch self {
        case .firstHabit: "leaf.fill"
        case .habitCreator5: "list.bullet.clipboard.fill"
        case .habitCreator10: "list.bullet.rectangle.portrait.fill"
        case .firstCompletion: "checkmark.circle.fill"
        case .habitsAllInOneDay5: "flame.fill"
        case .habitsAllInOneDay10: "flame.circle.fill"
        case .habitsAllInOneDayAll: "sun.max.circle.fill"
        case .streak3: "calendar.badge.clock"
        case .streak7: "flame.fill"
        case .streak14: "flame.circle.fill"
        case .streak30: "fireplace.fill"
        case .streak60: "sparkles"
        case .streak100: "flame.circle.fill"
        case .streak180: "bolt.horizontal.circle.fill"
        case .streak365: "crown.fill"
        case .points10: "star.fill"
        case .points50: "star.leadinghalf.filled"
        case .points100: "star.circle.fill"
        case .points250: "rosette"
        case .points500: "medal.fill"
        case .points1000: "stars.shield.fill"
        case .points2500: "diamond.fill"
        case .points5000: "crown.fill"
        case .measurableGoal100: "chart.line.uptrend.xyaxis"
        case .measurableGoal500: "chart.bar.fill"
        case .measurableGoal1000: "chart.bar.doc.horizontal.fill"
        case .pointsSingleDay10: "sun.and.flag.fill"
        case .pointsSingleDay20: "sun.max.fill"
        case .pointsSingleDay30: "sun.dust.fill"

        case .firstWorkout: "dumbbell.fill"
        case .workouts5: "figure.run"
        case .workouts10: "figure.run.square.stack.fill"
        case .workouts25: "figure.strengthtraining.traditional.fill"
        case .workouts50: "trophy.fill"
        case .workouts75: "trophy.circle.fill"
        case .workouts100: "trophy.fill"
        case .workouts200: "crown.fill"
        case .workoutDuration30: "timer"
        case .workoutDuration60: "clock.fill"
        case .workoutDuration90: "hourglass.bottomhalf.filled"
        case .firstPR: "arrow.up.circle.fill"
        case .prCount5: "arrow.up.arrow.circlepath"
        case .prCount15: "chart.xyaxis.line"
        case .prCount30: "record.circle"
        case .totalVolume1000: "scalemass.fill"
        case .totalVolume10000: "scalemass"
        case .totalVolume50000: "square.stack.3d.down.right.fill"
        case .totalVolume100000: "building.columns.fill"
        case .totalVolume250000: "mountain.2.fill"
        case .workout3DaysRow: "calendar.badge.plus"
        case .workout7DaysRow: "calendar.circle.fill"
        case .firstCardio: "heart.fill"
        case .firstStrength: "figure.strengthtraining.traditional"
        case .setsCompleted100: "list.number"
        case .setsCompleted500: "list.number.rtl"
        case .setsCompleted1000: "number.square.fill"

        case .firstTree: "tree.fill"
        case .trees3: "tree.fill"
        case .trees5: "forest.fill"
        case .trees10: "leaf.circle.fill"
        case .trees15: "tree.circle.fill"
        case .trees25: "forest.fill"
        case .trees40: "leaf.arrow.triangle.branch"
        case .firstOak: "tree.fill"
        case .firstPine: "tree.fill"
        case .firstBirch: "tree.fill"
        case .firstMaple: "tree.fill"
        case .firstWillow: "tree.fill"
        case .firstCherry: "tree.fill"
        case .firstSequoia: "tree.fill"
        case .firstBonsai: "tree.fill"
        case .treeGrowthSapling: "leaf.fill"
        case .treeGrowthYoung: "leaf.arrow.triangle.branch"
        case .treeGrowthMature: "tree.fill"
        case .treeGrowthAncient: "tree.circle.fill"
        case .treesAncient2: "mountain.2.fill"
        case .treesAncient5: "mountain.2.circle.fill"
        case .forestCoverage25: "chart.pie.fill"
        case .forestCoverage50: "chart.pie.fill"
        case .forestCoverage75: "chart.pie.fill"
        case .pointsSpent50: "leaf.arrow.triangle.circlepath"
        case .pointsSpent200: "leaf.arrow.triangle.merge"
        case .pointsSpent500: "leaf.circle"

        case .muscleBronze: "shield.fill"
        case .muscleBronze5: "shield.lefthalf.filled"
        case .muscleBronze10: "shield.righthalf.filled"
        case .muscleSilver: "shield.fill"
        case .muscleSilver5: "shield.lefthalf.filled"
        case .muscleSilver10: "shield.righthalf.filled"
        case .muscleGold: "shield.fill"
        case .muscleGold5: "shield.circle.fill"
        case .muscleGold10: "shield.circle"
        case .musclePlatinum: "seal.fill"
        case .musclePlatinum3: "seal"
        case .muscleDiamond: "diamond.fill"
        case .muscleChampion: "trophy.fill"
        case .muscleLegend: "crown.fill"
        case .muscleUpperBodyBronze: "figure.strengthtraining.traditional"
        case .muscleLowerBodyBronze: "figure.walk"
        case .muscleCoreBronze: "figure.core.training"
        case .muscleBackBronze: "figure.rowing"
        case .muscleFirstSet: "circle.fill"
        case .muscleSetsTotal100: "circle.grid.2x2.fill"
        case .muscleSetsTotal500: "circle.grid.3x3.fill"
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstHabit, .habitCreator5, .habitCreator10, .firstCompletion,
             .habitsAllInOneDay5, .habitsAllInOneDay10, .habitsAllInOneDayAll,
             .streak3, .streak7, .streak14, .streak30, .streak60, .streak100, .streak180, .streak365,
             .points10, .points50, .points100, .points250, .points500, .points1000, .points2500, .points5000,
             .measurableGoal100, .measurableGoal500, .measurableGoal1000,
             .pointsSingleDay10, .pointsSingleDay20, .pointsSingleDay30:
            return .habit

        case .firstWorkout, .workouts5, .workouts10, .workouts25, .workouts50, .workouts75, .workouts100, .workouts200,
             .workoutDuration30, .workoutDuration60, .workoutDuration90,
             .firstPR, .prCount5, .prCount15, .prCount30,
             .totalVolume1000, .totalVolume10000, .totalVolume50000, .totalVolume100000, .totalVolume250000,
             .workout3DaysRow, .workout7DaysRow,
             .firstCardio, .firstStrength,
             .setsCompleted100, .setsCompleted500, .setsCompleted1000:
            return .workout

        case .firstTree, .trees3, .trees5, .trees10, .trees15, .trees25, .trees40,
             .firstOak, .firstPine, .firstBirch, .firstMaple, .firstWillow, .firstCherry, .firstSequoia, .firstBonsai,
             .treeGrowthSapling, .treeGrowthYoung, .treeGrowthMature, .treeGrowthAncient, .treesAncient2, .treesAncient5,
             .forestCoverage25, .forestCoverage50, .forestCoverage75,
             .pointsSpent50, .pointsSpent200, .pointsSpent500:
            return .forest

        case .muscleBronze, .muscleBronze5, .muscleBronze10,
             .muscleSilver, .muscleSilver5, .muscleSilver10,
             .muscleGold, .muscleGold5, .muscleGold10,
             .musclePlatinum, .musclePlatinum3,
             .muscleDiamond, .muscleChampion, .muscleLegend,
             .muscleUpperBodyBronze, .muscleLowerBodyBronze, .muscleCoreBronze, .muscleBackBronze,
             .muscleFirstSet, .muscleSetsTotal100, .muscleSetsTotal500:
            return .muscle
        }
    }

    var targetValue: Int {
        switch self {
        case .firstHabit: 1
        case .habitCreator5: 5
        case .habitCreator10: 10
        case .firstCompletion: 1
        case .habitsAllInOneDay5: 1
        case .habitsAllInOneDay10: 1
        case .habitsAllInOneDayAll: 1
        case .streak3: 3
        case .streak7: 7
        case .streak14: 14
        case .streak30: 30
        case .streak60: 60
        case .streak100: 100
        case .streak180: 180
        case .streak365: 365
        case .points10: 10
        case .points50: 50
        case .points100: 100
        case .points250: 250
        case .points500: 500
        case .points1000: 1000
        case .points2500: 2500
        case .points5000: 5000
        case .measurableGoal100: 1
        case .measurableGoal500: 500
        case .measurableGoal1000: 1000
        case .pointsSingleDay10: 10
        case .pointsSingleDay20: 20
        case .pointsSingleDay30: 30

        case .firstWorkout: 1
        case .workouts5: 5
        case .workouts10: 10
        case .workouts25: 25
        case .workouts50: 50
        case .workouts75: 75
        case .workouts100: 100
        case .workouts200: 200
        case .workoutDuration30: 30
        case .workoutDuration60: 60
        case .workoutDuration90: 90
        case .firstPR: 1
        case .prCount5: 5
        case .prCount15: 15
        case .prCount30: 30
        case .totalVolume1000: 1000
        case .totalVolume10000: 10000
        case .totalVolume50000: 50000
        case .totalVolume100000: 100000
        case .totalVolume250000: 250000
        case .workout3DaysRow: 3
        case .workout7DaysRow: 7
        case .firstCardio: 1
        case .firstStrength: 1
        case .setsCompleted100: 100
        case .setsCompleted500: 500
        case .setsCompleted1000: 1000

        case .firstTree: 1
        case .trees3: 3
        case .trees5: 5
        case .trees10: 10
        case .trees15: 15
        case .trees25: 25
        case .trees40: 40
        case .firstOak: 1
        case .firstPine: 1
        case .firstBirch: 1
        case .firstMaple: 1
        case .firstWillow: 1
        case .firstCherry: 1
        case .firstSequoia: 1
        case .firstBonsai: 1
        case .treeGrowthSapling: 1
        case .treeGrowthYoung: 1
        case .treeGrowthMature: 1
        case .treeGrowthAncient: 1
        case .treesAncient2: 2
        case .treesAncient5: 5
        case .forestCoverage25: 25
        case .forestCoverage50: 50
        case .forestCoverage75: 75
        case .pointsSpent50: 50
        case .pointsSpent200: 200
        case .pointsSpent500: 500

        case .muscleBronze: 1
        case .muscleBronze5: 5
        case .muscleBronze10: 10
        case .muscleSilver: 1
        case .muscleSilver5: 5
        case .muscleSilver10: 10
        case .muscleGold: 1
        case .muscleGold5: 5
        case .muscleGold10: 10
        case .musclePlatinum: 1
        case .musclePlatinum3: 3
        case .muscleDiamond: 1
        case .muscleChampion: 1
        case .muscleLegend: 1
        case .muscleUpperBodyBronze: 1
        case .muscleLowerBodyBronze: 1
        case .muscleCoreBronze: 1
        case .muscleBackBronze: 1
        case .muscleFirstSet: 1
        case .muscleSetsTotal100: 100
        case .muscleSetsTotal500: 500
        }
    }
}