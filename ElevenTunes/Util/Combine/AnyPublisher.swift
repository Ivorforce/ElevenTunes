//
//  AnyPublisher.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 20.12.20.
//

import Foundation
import Combine

extension Publisher {
    func onMain() -> Publishers.ReceiveOn<Self, RunLoop> {
        return receive(on: RunLoop.main)
    }
    
    // Folds the result of the publisher until nil is returned.
    // This is useful for requests that warrant an immediate followup:
    // paginated(0)
    //    .fold { $0.page < $0.total ? paginated($0.page + 1) : nil  }
    //    .collect()
    func unfold(limit: Int = -1, _ fun: @escaping (Output) -> AnyPublisher<Output, Failure>?) -> Publishers.FlatMap<AnyPublisher<Self.Output, Self.Failure>, Self> {
        flatMap { value -> AnyPublisher<Output, Failure> in
            let justPublisher = Just(value).mapError { $0 as! Failure }
            
            guard limit != 0, let publisher = fun(value) else {
                return justPublisher.eraseToAnyPublisher()
            }
            return justPublisher.append(publisher.unfold(limit: limit - 1, fun)).eraseToAnyPublisher()
        }
    }

    // Like above, but fails on limit breach instead of just terminating.
    func unfold(limit: Int, failure: @escaping @autoclosure () -> Failure, _ fun: @escaping (Output) -> AnyPublisher<Output, Failure>?) -> Publishers.FlatMap<AnyPublisher<Self.Output, Self.Failure>, Self> {
        flatMap { value -> AnyPublisher<Output, Failure> in
            let justPublisher = Just(value).mapError { $0 as! Failure }
            
            guard limit != 0 else { return Fail(error: failure()).eraseToAnyPublisher() }
            
            guard let publisher = fun(value) else {
                return justPublisher.eraseToAnyPublisher()
            }
            return justPublisher.append(publisher.unfold(limit: limit - 1, fun)).eraseToAnyPublisher()
        }
    }

    func eraseError() -> Publishers.MapError<Self, Error> {
        return mapError { $0 as Error }
    }
}

extension Publisher where Failure == Never {
    func assignWeak<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
       sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
