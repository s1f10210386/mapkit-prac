//
//  ARView.swift
//  mapkit-prac
//
//  Created by 金澤帆高 on 2024/02/07.
//

import SwiftUI
import RealityKit
import ARKit

struct ARContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        //水平面になったらセッションを開始する
        let session = arView.session
        let config = ARGeoTrackingConfiguration()
        config.planeDetection = .horizontal
        session.run(config)
        
        //ARの処理をcoordinatorで行うのでcoordinatorに情報を渡す
        context.coordinator.arView = arView
        //arviewにCoachingOvelayViewを追加する（setUpCoachingOverLay() はARView+Extensionファイルにあります）
        arView.setupCoachingOverlay(context.coordinator)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    //Coordinatorを作成
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ARContentView()
    }
}
#endif


