//
//  ServerConnetion.swift
//  STransportLayer
//
//  Created by Vlad on 24.11.2020.
//

import Foundation
import Network

//The TCP maximum package size is 64K 65536
let tcpMAX = 65536

class ServerConnection {
    
    private static var nextID: Int = 0
    let  connection: NWConnection
    let id: Int
    
    var delegate: NetworkDelegate?

    init(nwConnection: NWConnection) {
        connection = nwConnection
        id = ServerConnection.nextID
        ServerConnection.nextID += 1
    }

    var didStopCallback: ((Error?) -> Void)? = nil

    func start() {
        delegate?.log(message: "connection \(id) will start")
        connection.stateUpdateHandler = self.stateDidChange(to:)
        setupReceive()
        connection.start(queue: .main)
    }

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            delegate?.log(message: "connection \(id) ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }

    private func setupReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: tcpMAX) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8)
                delegate?.log(message: "connection \(self.id) did receive, data: \(data as NSData) string: \(message ?? "-")")
                self.send(data: data)
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
    
    var count = 0
    var final = false
    

    func send(data: Data) {
        self.connection.send(content: data, contentContext: .defaultStream, isComplete: false, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            self.count += 1
            let data = "\(self.count)".data(using: .utf8)!
            if self.count < 999 {
                self.send(data: data)
            }
//            self.final = !self.final
//            if self.final {
//                self.send(data: nil)
//            } else {
//                self.count += 1
//                let data = "\(self.count)".data(using: .utf8)!
//                if self.count < 999 {
//                    self.send(data: data)
//                }
//            }
            delegate?.log(message: "connection \(self.id) did send, data: \(data as NSData)")
        }))
    }

    func stop() {
        delegate?.log(message: "connection \(id) will stop")
    }

    private func connectionDidFail(error: Error) {
        delegate?.log(message: "connection \(id) did fail, error: \(error)")
        stop(error: error)
    }

    private func connectionDidEnd() {
        delegate?.log(message: "connection \(id) did end")
        stop(error: nil)
    }

    private func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
}
