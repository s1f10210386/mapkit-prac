//
//  Coordinator.swift
//  ARKit-prac
//
//  Created by 金澤帆高 on 2024/02/12.
//

import Foundation
import RealityKit
import ARKit
import CoreLocation
import Combine

struct NavigationPoint {
    var latitude: Double
    var longitude: Double
}

class Coordinator: NSObject, CLLocationManagerDelegate ,ARCoachingOverlayViewDelegate{
    var arView: ARView?
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var locationViewModel: LocationViewModel?
    private var cancellables = Set<AnyCancellable>()
    var referenceObjects: Set<ARReferenceObject> = []
    
    init(locationViewModel: LocationViewModel) {
        self.locationViewModel = locationViewModel
    }
    
    //    init(locationViewModel: LocationViewModel? = nil) {
    //        self.locationViewModel = locationViewModel
    //        super.init()
    //        setupLocationManager()
    //        setupBindings()
    //    }
    
    func debugLocationViewModel() {
        let address = Unmanaged.passUnretained(self).toOpaque()
        print("LocationViewModelのインスタンスアドレス: \(address)")
        // locationViewModelがnilではないことを確認
        if let viewModel = locationViewModel {
            // coordinatesが空でないことを確認
            if !viewModel.coordinates.isEmpty {
                print("デバッグ: 現在の座標データは以下の通りです。")
                for coordinate in viewModel.coordinates {
                    print("緯度: \(coordinate.latitude), 経度: \(coordinate.longitude)")
                }
            } else {
                // coordinatesが空の場合
                print("デバッグ: 座標データは空です。")
            }
        } else {
            // locationViewModelがnilの場合
            print("デバッグ: locationViewModelは利用できません。")
        }
    }
    
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        
    }
    
    private func setupBindings() {
        locationViewModel?.$coordinates
            .sink(receiveValue: { [weak self] coordinates in
                self?.updateARView(with: coordinates)
            })
            .store(in: &cancellables)
    }
    
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // コーチングオーバーレイが非アクティブになったら、最新の座標でARビューを更新する
        if let coordinates = self.locationViewModel?.coordinates {
            updateARView(with: coordinates)
        } else {
            print("最新の座標データがまだ利用可能ではありません。")
        }
    }
    
    
    private func updateARView(with coordinates: [CLLocationCoordinate2D]) {
        
        //表示したい場所の緯度と経度を入力(とりあえず赤羽公園)
        let start = CLLocationCoordinate2D(latitude: 35.77944657902831, longitude: 139.72491032371784)
        let end = CLLocationCoordinate2D(latitude: 35.78030260912687, longitude: 139.7245143723517)
        let mid = CLLocationCoordinate2D(latitude: 35.77987459407759, longitude: 139.72471234803476)
        
        let startRad: Float = .pi/2
        let midRad: Float = -.pi/2
        
        
        //start +90するから想定では現実世界の北
        let geoAnchor = ARGeoAnchor(coordinate: start)
        //        let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width:1,depth:50))
        if let modelEntity = try? Entity.loadModel(named: "arrow") {
            modelEntity.scale = SIMD3<Float>(0.2, 0.2, 0.2)
            modelEntity.transform.rotation = simd_quatf(angle: .pi/2 - 2.204430958886927, axis: [0, 1, 0])
            let anchorEntity = AnchorEntity(anchor: geoAnchor) // 適切な位置に配置
            anchorEntity.addChild(modelEntity)
            arView?.session.add(anchor: geoAnchor)
            arView?.scene.addAnchor(anchorEntity)
        }
        
        //mid -90するから想定では現実世界の南
        let geoAnchor2 = ARGeoAnchor(coordinate: mid)
        //        let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width:1,depth:50))
        if let modelEntity2 = try? Entity.loadModel(named: "arrow") {
            modelEntity2.scale = SIMD3<Float>(0.1, 0.1, 0.1)
            modelEntity2.transform.rotation = simd_quatf(angle: .pi/2 - 0.6336346320920306, axis: [0, 1, 0])
            let anchorEntity2 = AnchorEntity(anchor: geoAnchor2) // 適切な位置に配置
            anchorEntity2.addChild(modelEntity2)
            
            arView?.session.add(anchor: geoAnchor2)
            arView?.scene.addAnchor(anchorEntity2)
        }
        
        
        DispatchQueue.main.async {
            for i in 0..<coordinates.count - 1 {
                let start = coordinates[i]
                let end = coordinates[i + 1]
                
                //ラジアン計算
                let bearingRadians = atan2(end.longitude - start.longitude, end.latitude - start.latitude)
                
                if let modelEntity = try? Entity.loadModel(named: "arrow") {
                    modelEntity.scale = SIMD3<Float>(0.2, 0.2, 0.2)
                    modelEntity.transform.rotation = simd_quatf(angle: .pi/2 - Float(bearingRadians), axis: [0, 1, 0])
                    
                    let geoAnchor = ARGeoAnchor(coordinate: start)
                    let anchorEntity = AnchorEntity(anchor: geoAnchor) // 適切な位置に配置
                    anchorEntity.addChild(modelEntity)
                    
                    self.arView?.session.add(anchor: geoAnchor)
                    self.arView?.scene.addAnchor(anchorEntity)
                    
                    
                }
                
            }
            
            func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
                guard let objectAnchor = anchor as? ARObjectAnchor else { return }
                
                // メインスレッドでUIの更新を行う
                DispatchQueue.main.async {
                    // 物体の上に球体を配置する
                    let sphere = SCNSphere(radius: 0.05) // 球体のサイズを設定
                    let sphereNode = SCNNode(geometry: sphere)
                    sphereNode.position = SCNVector3(0, 0.05, 0) // 物体の中心より少し上に配置
                    
                    // 球体のマテリアル（外観）を設定
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.red // 色を赤に設定
                    sphere.materials = [material]
                    
                    node.addChildNode(sphereNode) // 認識された物体のノードに球体を追加
                }
            }
            
            //        DispatchQueue.main.async {
            //            coordinates.forEach { coordinate in
            //                let geoAnchor = ARGeoAnchor(coordinate: coordinate) //固定点
            //#if !targetEnvironment(simulator)
            //                let anchorEntity = AnchorEntity(anchor: geoAnchor) //オブジェクトの枠組み
            //#else
            //                let anchorEntity = AnchorEntity()
            //#endif
            ////                let modelEntity = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.5)) //オブジェ
            //                let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width:1,depth:1))
            //                let material = SimpleMaterial(color: .blue, isMetallic: false)
            //                modelEntity.components[ModelComponent.self]?.materials = [material]
            //                anchorEntity.addChild(modelEntity)
            //
            //                self.arView?.session.add(anchor: geoAnchor) //仮想オブジェクトをどこに固定するか決定
            //                self.arView?.scene.addAnchor(anchorEntity)
            //            }
            //
            //        }
            
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            self.currentLocation = locations.first
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print(error)
        }
        
    }
    //        navigationPoints .forEach { point in //for文で１つずつオブジェクト化
    //            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
    //            let geoAnchor = ARGeoAnchor(coordinate: coordinate)
    //            // 実機
    //#if !targetEnvironment(simulator)
    //            let anchorEntity = AnchorEntity(anchor: geoAnchor)
    //#else
    //            // シミュレータ
    //            let anchorEntity = AnchorEntity()
    //#endif
    //
    //            let modelEntity = ModelEntity(mesh: MeshResource.generateBox(size: 1.0))
    //            anchorEntity.addChild(modelEntity)
    //
    //            arView?.session.add(anchor: geoAnchor) // 仮想オブジェクトをどこに固定するか決定
    //            arView?.scene.addAnchor(anchorEntity) // オブジェクトを実際に配置
    
    
}
