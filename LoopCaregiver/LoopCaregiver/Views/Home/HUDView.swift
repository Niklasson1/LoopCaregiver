//
//  HUDView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/17/22.
//

import SwiftUI
import NightscoutClient
import Combine

struct HUDView: View {
    
    @ObservedObject var hudViewModel: HUDViewModel
    @ObservedObject var nightscoutDateSource: NightscoutDataSource
    
    static let nowDate: () -> Date = {Date()}
    
    init(looperService: LooperService, selectedLooper: Looper){
        self.hudViewModel = HUDViewModel(selectedLooper: selectedLooper, looperService: looperService)
        self.nightscoutDateSource = selectedLooper.nightscoutDataSource
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack (alignment: .center) {
                    Text(formatEGV(nightscoutDateSource.currentEGV))
                        .font(.largeTitle)
                        .foregroundColor(egvValueColor())
                        .padding([.leading, .top])
                    if let lastEGVChange = self.lastEGVChange() {
                        Text("\(lastEGVChange)")
                            .font(.footnote)
                    }
                }
                if let egv = nightscoutDateSource.currentEGV {
                    Image(systemName: arrowImageName(egv: egv))
                        .foregroundColor(egvValueColor())
                }
                Spacer()
                Picker("Looper", selection: $hudViewModel.selectedLooper) {
                    ForEach(hudViewModel.loopers()) { looper in
                        Text(looper.name).tag(looper)
                    }
                }
            }

        }
    }
    
    func arrowImageName(egv: NightscoutEGV) -> String {
    
        guard let trendRate = egv.trendRate else {
            return "questionmark"
        }
        
        guard let trend = EGVTrend(rawValue: Int(trendRate)) else { //TODO: Could crash on large values
            return "questionmark"
        }
        
        switch trend {
            
        case .doubleUp:
            return "arrow.up"
        case .singleUp:
            return  "arrow.up"
        case .fortyFiveUp:
            return  "arrow.up.forward"
        case .flat:
            return  "arrow.right"
        case .fortyFiveDown:
            return  "arrow.down.forward"
        case .singleDown:
            return  "arrow.down"
        case .doubleDown:
            return  "arrow.down"
        case .nonComputable:
            return  "questionmark"
        case .outOfRange:
            return  "questionmark"
        }
    }
    
    func lastEGVChange() -> Int? {
        let egvs = nightscoutDateSource.egvs
        guard egvs.count > 1 else {
            return nil
        }
        
        return egvs[egvs.count - 1].value - egvs[egvs.count - 2].value
    }
    
    func egvValueColor() -> Color {
        if let currentEGV = nightscoutDateSource.currentEGV {
            return ColorType(egvValue: currentEGV.value).color
        } else {
            return .white
        }
    }
    
    func formatEGV(_ egv: NightscoutEGV?) -> String {
        if let egv {
            return String(egv.value)
        } else {
            return " " //Using spaces, rather than a characterless String, to avoid view elements from jumping during load.
        }
    }
    
    enum EGVTrend: Int {
        case doubleUp = 1
        case singleUp = 2
        case fortyFiveUp = 3
        case flat = 4
        case fortyFiveDown = 5
        case singleDown = 6
        case doubleDown = 7
        case nonComputable = 8
        case outOfRange = 9
    }
    
    func arrowForTrend(rawValue: Int?) -> String {
        guard let rawValue, let egvTrend = EGVTrend(rawValue: rawValue) else {
            return "?"
        }
        
        switch egvTrend {
        case .doubleUp:
            return ""
        default:
            return ""
        }
        
    }
}

class HUDViewModel: ObservableObject {
    
    @Published var selectedLooper: Looper {
        didSet {
            do {
                try looperService.updateActiveLoopUser(selectedLooper)
            } catch {
                print(error)
            }
        }
    }
    @ObservedObject var looperService: LooperService
    private var subscribers: Set<AnyCancellable> = []
    
    init(selectedLooper: Looper, looperService: LooperService) {
        self.selectedLooper = selectedLooper
        self.looperService = looperService
        
        self.looperService.$selectedLooper.sink { val in
        } receiveValue: { [weak self] updatedUser in
            if let self, let updatedUser, self.selectedLooper != updatedUser {
                self.selectedLooper = updatedUser
            }
        }.store(in: &subscribers)
    }
    
    func loopers() -> [Looper] {
        return looperService.loopers
    }
}
