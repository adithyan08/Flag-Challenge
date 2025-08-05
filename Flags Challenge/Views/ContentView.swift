//
//  ContentView.swift
//  Flags Challenge
//
//  Created by adithyan na on 5/8/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @StateObject var vm: FlagsChallengeViewModel
    @State private var showSchedule = true
    
    init(context: NSManagedObjectContext) {
        _vm = StateObject(wrappedValue: FlagsChallengeViewModel(context: context))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if showSchedule {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.brandOrange)
                        .frame(height: 80)
                    if vm.isCountingDown {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                            .frame(width: 70, height: 36)
                            .overlay(
                                Text(String(format: "00:%02d", vm.countdownToStart))
                                    .foregroundColor(.white)
                                    .font(.title3.monospacedDigit())
                            )
                            .padding(.leading)
                            .padding(.top, 12)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .background(Color.white)
                        .cornerRadius(12)
                    
                    VStack(spacing: 8) {
                        Text("FLAGS CHALLENGE")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Color.brandOrange)
                            .padding(.vertical, 16)
                        
                        HStack(spacing: 6) {
                            Text("CHALLENGE")
                                .font(.headline)
                            Text("SCHEDULE")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .padding(2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(2)
                        }
                        
                        HStack(spacing: 18) {
                            timeInputField(title: "Hour", value: $vm.hours)
                            timeInputField(title: "Minute", value: $vm.minutes)
                            timeInputField(title: "Second", value: $vm.seconds)
                        }
                        .padding(.top, 6)
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                vm.saveScheduledDuration(hours: vm.hours, minutes: vm.minutes, seconds: vm.seconds)
                                showSchedule = false
                            }
                        }) {
                            Text("Save")
                                .font(.title3)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.brandOrange)
                                .foregroundColor(.white)
                                .cornerRadius(7)
                        }
                        .padding(.vertical, 12)
                        .disabled(vm.isCountingDown)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: 370)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
            
            contentView()
                .padding()
                .frame(maxWidth: 380)
            
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .onDisappear {
            vm.stopTimer()
            vm.saveState()
        }
    }
    
    @ViewBuilder
    func contentView() -> some View {
        switch vm.phase {
        case .waitingForSchedule, .countdownToStart:
            EmptyView()
        case .question:
            questionView()
        case .interval:
            intervalView()
        case .finished:
            finishedView()
        }
    }
    
    func questionView() -> some View {
        guard vm.currentQuestionIndex < vm.questions.count else { return AnyView(EmptyView()) }
        let q = vm.questions[vm.currentQuestionIndex]
        return AnyView(
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Question \(vm.currentQuestionIndex + 1)/\(vm.questions.count)")
                        .font(.headline)
                    Spacer()
                    Text(timerString(vm.questionTimer))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandOrange)
                }
                Text("Guess the Country by the Flag")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                HStack {
                    Spacer()
                    SafeFlagImage(imageName: q.flagImageName)
                        .scaledToFit()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 3)
                    Spacer()
                }
                VStack(spacing: 12) {
                    ForEach(q.options.indices, id: \.self) { idx in
                        Button {
                            vm.selectOption(idx)
                        } label: {
                            HStack {
                                Text(q.options[idx])
                                Spacer()
                            }
                            .padding()
                            .background(buttonBackground(idx: idx))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(optionBorder(idx: idx), lineWidth: 2)
                            )
                        }
                        .disabled(vm.isResultShown)
                        .overlay(
                            VStack(alignment: .leading) {
                                if vm.isResultShown {
                                    if idx == q.correctOptionIndex {
                                        Text("Correct")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                            .padding(.leading, 8)
                                    } else if idx == vm.selectedIndex && vm.selectedIndex != q.correctOptionIndex {
                                        Text("Wrong")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                            .padding(.leading, 8)
                                    }
                                }
                            }
                            .offset(y: 32)
                        )
                    }
                }
                .padding(.top, 20)
            }
        )
    }
    
    func intervalView() -> some View {
        VStack(spacing: 20) {
            Text("Next question in \(vm.intervalTimer) seconds...")
                .font(.title2)
                .foregroundColor(Color.brandOrange)
        }
    }
    
    func finishedView() -> some View {
        VStack(spacing: 24) {
            Text("GAME OVER")
                .font(.largeTitle)
                .bold()
                .foregroundColor(Color.brandOrange)
            Text("SCORE : \(vm.score)/\(vm.questions.count)")
                .font(.title2)
        }
    }
    
    func buttonBackground(idx: Int) -> Color {
        guard vm.currentQuestionIndex < vm.questions.count else { return Color.clear }
        let q = vm.questions[vm.currentQuestionIndex]
        if !vm.isResultShown {
            return vm.selectedIndex == idx ? Color.optionSelectedBg : Color.white
        } else {
            if idx == q.correctOptionIndex {
                return Color.optionCorrectBg
            } else if idx == vm.selectedIndex {
                return Color.optionWrongBg
            } else {
                return Color.white
            }
        }
    }
    
    func optionBorder(idx: Int) -> Color {
        guard vm.currentQuestionIndex < vm.questions.count else { return Color.clear }
        let q = vm.questions[vm.currentQuestionIndex]
        if !vm.isResultShown {
            return vm.selectedIndex == idx ? Color.orange : Color.gray.opacity(0.3)
        } else {
            if idx == q.correctOptionIndex { return Color.green }
            if idx == vm.selectedIndex { return Color.red }
            return Color.gray.opacity(0.3)
        }
    }
    
    func timerString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    func timeInputField(title: String, value: Binding<Int>) -> some View {
        VStack(spacing: 6) {
            TextField("", value: value, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .frame(width: 50, height: 44)
                .background(Color(white: 0.9))
                .cornerRadius(8)
                .multilineTextAlignment(.center)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview

struct ScheduleChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        ContentView(context: context)
    }
}
