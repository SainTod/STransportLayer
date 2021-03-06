//
//  Client.swift
//  STransportLayer
//
//  Created by Vlad on 24.11.2020.
//

import Foundation
import Network

class Client {
    
    let connection: ClientConnection
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    
    var delegate: NetworkDelegate? {
        didSet {
            connection.delegate = delegate
        }
    }

    init(host: String, port: UInt16) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        let nwConnection = NWConnection(host: self.host, port: self.port, using: .tcp)
        connection = ClientConnection(nwConnection: nwConnection)
    }

    func start() {
        delegate?.log(message: "Client started \(host) \(port)")
        connection.didStopCallback = didStopCallback(error:)
        connection.start()
    }

    func stop() {
        connection.stop()
    }

    func send(data: Data) {
        connection.send(data: data)
    }

    func didStopCallback(error: Error?) {
        if error == nil {
            exit(EXIT_SUCCESS)
        } else {
            exit(EXIT_FAILURE)
        }
    }
}
