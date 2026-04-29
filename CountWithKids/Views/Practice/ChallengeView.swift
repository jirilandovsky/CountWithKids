import SwiftUI
import UIKit

struct ChallengeView: View {
    @Environment(\.appTheme) var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var settings: AppSettings
    /// True when the calling flow is the Guided Learning tier — enables
    /// scaffolded hints. Free-tier challenges keep the drill experience pure.
    var hintsEnabled: Bool = false
    let onDismiss: () -> Void

    @State private var viewModel = ChallengeViewModel()
    @FocusState private var answerFocused: Bool
    @State private var appeared = false
    @State private var showResultButton = false
    @State private var mascotScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            switch viewModel.state {
            case .prompt:
                promptView
            case .racing:
                racingView
            case .finished:
                resultView
            }
        }
        .onDisappear {
            viewModel.reset()
        }
    }

    // MARK: - Prompt (speech bubble)

    private var promptView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(theme.mascotEmoji)
                .font(.system(size: 120))
                .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.5))
                .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.6), value: appeared)
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Text(loc("Think you can beat me? Let's race!"))
                    .playfulFont(.title3)
                    .foregroundColor(theme.primaryColor)
                    .multilineTextAlignment(.center)

                Text(String(format: loc("%d problems, who's faster?"), ChallengeViewModel.problemCount))
                    .playfulFont(.callout, weight: .medium)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .clayCard(cornerRadius: 28, elevation: .floating)
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : (reduceMotion ? 0 : 20))
            .animation(.easeOut(duration: 0.4).delay(reduceMotion ? 0 : 0.2), value: appeared)

            Button(loc("Let's go!")) {
                viewModel.hintsEnabled = hintsEnabled
                viewModel.startRace(settings: settings)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    answerFocused = true
                }
            }
            .buttonStyle(PlayfulButtonStyle())
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(reduceMotion ? 0 : 0.5), value: appeared)

            Button(loc("Maybe later")) {
                onDismiss()
            }
            .playfulFont(.callout, weight: .medium)
            .foregroundColor(.secondary)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(reduceMotion ? 0 : 0.6), value: appeared)

            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }

    // MARK: - Racing

    private var racingView: some View {
        VStack(spacing: 0) {
            // Top: mascot icon centered
            Text(theme.mascotEmoji)
                .font(.system(size: 48))
                .scaleEffect(mascotScale)
                .padding(.top, 12)
                .accessibilityHidden(true)
                .onChange(of: viewModel.mascotSolved) { _, _ in
                    guard !reduceMotion else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        mascotScale = 1.2
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4).delay(0.2)) {
                        mascotScale = 1.0
                    }
                }

            // Mascot shootout circles centered
            shootoutCircles(
                total: ChallengeViewModel.problemCount,
                results: nil,
                mascotSolved: viewModel.mascotSolved,
                color: theme.secondaryColor
            )
            .padding(.top, 8)

            Divider()
                .padding(.horizontal)
                .padding(.top, 8)

            // Countdown clock — centered in the middle area
            Spacer()

            // Current problem — inline layout
            if let problem = viewModel.currentProblem {
                VStack(spacing: 16) {
                    if let hint = viewModel.currentHint {
                        hintBubble(hint)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Countdown clock
                    Text(viewModel.countdownString)
                        .playfulFont(.title)
                        .foregroundColor(viewModel.countdownSeconds < 10 ? theme.secondaryColor : theme.primaryColor)
                        .monospacedDigit()

                    // Problem + answer on one line
                    HStack(spacing: 12) {
                        Text(problem.displayString)
                            .playfulFont(.title)
                            .foregroundColor(.primary)
                            .environment(\.layoutDirection, .leftToRight)

                        if problem.operation == .subtract {
                            Button {
                                viewModel.toggleNegative()
                            } label: {
                                Text(viewModel.isCurrentNegative ? "−" : "+/−")
                                    .playfulFont(.callout)
                                    .foregroundColor(viewModel.isCurrentNegative ? theme.secondaryColor : .secondary)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(viewModel.isCurrentNegative ? theme.secondaryColor.opacity(0.15) : Color.gray.opacity(0.1))
                                    )
                            }
                            .accessibilityLabel(loc(viewModel.isCurrentNegative ? "Negative answer on" : "Toggle negative answer"))
                        }

                        HStack(spacing: 2) {
                            if viewModel.isCurrentNegative {
                                Text("−")
                                    .playfulFont(.title)
                                    .foregroundColor(theme.secondaryColor)
                            }

                            TextField("?", text: $viewModel.currentAnswer)
                                .keyboardType(.numberPad)
                                .playfulFont(.title)
                                .multilineTextAlignment(.center)
                                .frame(width: 80, height: 52)
                                .accessibilityLabel(loc("Your answer"))
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(theme.primaryColor.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(theme.primaryColor, lineWidth: 3)
                                )
                                .focused($answerFocused)
                                .onSubmit {
                                    viewModel.submitAnswer()
                                    answerFocused = true
                                }
                                .onChange(of: viewModel.currentAnswer) { _, newValue in
                                    viewModel.currentAnswer = newValue.filter { $0.isNumber }
                                }
                        }
                    }

                    Button(loc("Next")) {
                        viewModel.submitAnswer()
                        answerFocused = true
                    }
                    .buttonStyle(PlayfulButtonStyle())
                }
                .padding()
            } else if viewModel.playerFinished && viewModel.state == .racing {
                // Player finished, waiting for mascot
                VStack(spacing: 12) {
                    Text(viewModel.countdownString)
                        .playfulFont(.title)
                        .foregroundColor(viewModel.countdownSeconds < 10 ? theme.secondaryColor : theme.primaryColor)
                        .monospacedDigit()

                    Text(loc("Waiting for the mascot to finish..."))
                        .playfulFont(.headline, weight: .medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Divider()
                .padding(.horizontal)

            // Player shootout circles centered
            shootoutCircles(
                total: ChallengeViewModel.problemCount,
                results: viewModel.playerResults,
                mascotSolved: nil,
                color: theme.primaryColor
            )
            .padding(.vertical, 12)
        }
    }

    // MARK: - Hint bubble (Guided Learning only)

    private func hintBubble(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(theme.mascotEmoji)
                .font(.system(size: 28))
                .accessibilityHidden(true)
            Text(text)
                .playfulFont(.subheadline, weight: .medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .clayCard(cornerRadius: 18, elevation: .resting)
        }
        .frame(maxWidth: 320)
        .padding(.horizontal)
    }

    // MARK: - Shootout circles (penalty-style)

    private func shootoutCircles(total: Int, results: [Bool]?, mascotSolved: Int?, color: Color) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 2)
                        .frame(width: 36, height: 36)

                    if let results, index < results.count {
                        Image(systemName: results[index] ? "checkmark" : "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(results[index] ? .green : theme.secondaryColor)
                    } else if let mascotSolved, index < mascotSolved {
                        // Mascot always correct — always green
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    // MARK: - Result

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Always show mascot emoji at the top
            Text(theme.mascotEmoji)
                .font(.system(size: 100))
                .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.3))
                .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.6, dampingFraction: 0.5), value: appeared)
                .accessibilityHidden(true)

            // Results: two separate cards, winner gets glowing border
            VStack(spacing: 12) {
                let mascotWon = viewModel.result == .mascotWins

                // Mascot card
                resultCard(
                    circles: AnyView(shootoutCircles(
                        total: ChallengeViewModel.problemCount,
                        results: nil,
                        mascotSolved: viewModel.mascotSolved,
                        color: theme.secondaryColor
                    )),
                    time: viewModel.mascotFinishTime.map { viewModel.formatTime($0) },
                    isWinner: mascotWon
                )

                // Player card
                resultCard(
                    circles: AnyView(shootoutCircles(
                        total: ChallengeViewModel.problemCount,
                        results: viewModel.playerResults,
                        mascotSolved: nil,
                        color: theme.primaryColor
                    )),
                    time: viewModel.playerFinishTime.map { viewModel.formatTime($0) },
                    isWinner: !mascotWon
                )
            }
            .padding(.horizontal, 20)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(reduceMotion ? 0 : 0.3), value: appeared)

            // Encouraging message (rotated from 10 variants)
            encouragingMessage
                .playfulFont(.headline, weight: .medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(reduceMotion ? 0 : 0.6), value: appeared)

            Spacer()

            if showResultButton {
                VStack(spacing: 12) {
                    Button(loc("Rematch!")) {
                        appeared = false
                        showResultButton = false
                        viewModel.hintsEnabled = hintsEnabled
                        viewModel.startRace(settings: settings)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            answerFocused = true
                        }
                    }
                    .buttonStyle(PlayfulButtonStyle())

                    Button(loc("Done")) {
                        onDismiss()
                    }
                    .buttonStyle(PlayfulButtonStyle(color: theme.secondaryColor))
                }
                .padding(.horizontal, 40)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
                .frame(height: 40)
        }
        .padding()
        .onAppear {
            handleResultAppear()
        }
    }

    // MARK: - Result card

    private func resultCard(circles: AnyView, time: String?, isWinner: Bool) -> some View {
        VStack(spacing: 6) {
            circles
            if let time {
                Text(time)
                    .playfulFont(.footnote, weight: .medium)
                    .foregroundColor(isWinner ? theme.accentColor : .secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .clayCard(cornerRadius: 22, elevation: isWinner ? .raised : .resting)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isWinner ? theme.accentColor : .clear, lineWidth: 2.5)
        )
        .shadow(color: isWinner ? theme.accentColor.opacity(0.35) : .clear,
                radius: isWinner ? 12 : 0, x: 0, y: 0)
    }

    // MARK: - Encouraging messages (10 per outcome, rotated)

    private static let winMessages = [
        "Amazing! You're on your way to becoming a math superhero!",
        "You did it! That was lightning fast!",
        "Wow, you're faster than the mascot! Incredible!",
        "Super brain! You nailed every single one!",
        "Math champion! The mascot didn't stand a chance!",
        "Perfect score AND faster? You're unstoppable!",
        "Brilliant! You solved them all without a single mistake!",
        "The mascot is impressed! You're a true math star!",
        "Fantastic! Keep it up and you'll be the fastest ever!",
        "You crushed it! The mascot wants a rematch!"
    ]

    private static let loseMessages = [
        "So close! Don't worry, next time you'll beat me for sure!",
        "Great effort! Practice makes perfect — try again!",
        "Almost there! You're getting faster every time!",
        "Don't give up! The mascot is just a little quicker... for now!",
        "Nice try! A few more rounds and you'll be the winner!",
        "You're learning fast! The mascot is starting to sweat!",
        "Good job finishing! Keep practicing and you'll win next time!",
        "That was close! One more try and you've got this!",
        "The mascot got lucky this time! Ready for a rematch?",
        "You're getting better! The mascot can feel it!"
    ]

    @ViewBuilder
    private var encouragingMessage: some View {
        let idx = viewModel.messageIndex
        switch viewModel.result {
        case .playerWins:
            Text(loc(Self.winMessages[idx]))
        case .mascotWins:
            Text(loc(Self.loseMessages[idx]))
        case nil:
            EmptyView()
        }
    }

    private func handleResultAppear() {
        if viewModel.result == .playerWins {
            settings.challengeWins += 1
        }

        withAnimation {
            appeared = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showResultButton = true
            }
        }
    }
}
