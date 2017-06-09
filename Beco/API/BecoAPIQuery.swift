//
//  BecoAPIQuery.swift
//  Beco
//
//  Copyright © 2015 Beco. All rights reserved.
//

import UIKit

class BecoAPIQuery: NSObject
{

    var retried = false

    var url: String
    {
        // All the new requests use http auth.
        // + "?token=\(apiToken)"
        return baseURL + getAPIURL()
    }

    var baseURL: String
    {
        return "https://\(ServerConnection.serverHost)"
    }

    var success = false

    enum Result
    {
        case ok
        case noInternet
        case dnsFailed
        case connectionFailed
        case queryFailed
    }

    func makeRequest(_ completion: @escaping ( Result ) -> Void )
    {
        let url = self.url
        let nsUrl = URL(string: url)
        let method = getHttpMethod()
        let useJson = getUseJson()

        let request = NSMutableURLRequest(url: nsUrl!)

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if useJson {
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
        }
        else {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        }

        if (method == "POST" || method == "PATCH") {
            request.httpMethod = method

            let postContents = getPOSTContents()

            if useJson {
                do {
                    let postJson = try JSONSerialization.data(withJSONObject: postContents, options: JSONSerialization.WritingOptions(rawValue:0))
                    request.httpBody = postJson
                }
                catch { }
            }
            else {
                var postString = String()
                for (id, str) in postContents {
                    if postString != "" {
                        postString.append("&")
                    }
                    postString.append("\(id)=\(str)")
                }
                gLog.debug("POSTing: \(postString)")
                request.httpBody = postString.data(using: .utf8)
            }
        }

        if useJson {
            let user = ServerConnection.sharedInstance.user!
            let authString = "\(user.email):\(user.password)"
            let authData: Data = authString.data(using: String.Encoding.utf8)!
            let encoded = authData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue:0))
            let authValue = "Basic \(encoded)"
            request.setValue(authValue, forHTTPHeaderField: "Authorization")
        }
        else {
            let authValue = "No Auth"
            request.setValue(authValue, forHTTPHeaderField: "Authorization")
        }
        gLog.debug("\(request)")
        let task = ServerConnection.session!.dataTask(with: request as URLRequest)
        {
            (data, response, error) in
            let httpResponse = response as? HTTPURLResponse

            if( httpResponse == nil ) {
                if (error! as NSError).code == NSURLErrorDNSLookupFailed {
                    if !self.retried {
                        gLog.info("HTTP query failed; retrying")
                        self.retried = true

                        DispatchQueue.main.async
                        {
                            self.makeRequest(completion)
                        }
                    }
                    else {
                        DispatchQueue.main.async
                        {
                            completion(Result.dnsFailed)
                        }
                    }
                }
                else if (error! as NSError).code == NSURLErrorNotConnectedToInternet {
                    DispatchQueue.main.async
                    {
                        completion(Result.noInternet)
                    }
                }
                else {
                    gLog.error("Received NIL Query Response for Request: \(request) with Error: \((error! as NSError).code)")
                    DispatchQueue.main.async
                    {
                        completion(Result.connectionFailed)
                    }
                }

                return;
            }

            print("URL request completed: HTTP \(httpResponse!.statusCode)")

            if data == nil {
                completion(Result.queryFailed)
            }
            else if httpResponse!.statusCode == 200 {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue:0)) as! NSDictionary

                    let success = self.handleResponse(json)
                    self.success = success

                    DispatchQueue.main.async
                    {
                        completion(Result.ok)
                    }
                }
                catch {
                    DispatchQueue.main.async
                    {
                        completion(Result.queryFailed)
                    }
                }
            }
            else {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue:0)) as? NSDictionary

                    self.handleError(json)
                }
                catch { }

                DispatchQueue.main.async
                {
                    completion(Result.queryFailed)
                }
            }
        }

        task.resume()
    }


    func handleError(_ json: NSDictionary? )
    {
        print("Handling error")
        print(json as Any)
    }


    func getAPIURL() -> String
    {
        preconditionFailure("getAPIURL must be overridden")
    }

    func getHttpMethod() -> String
    {
        return "GET"
    }

    func getUseJson() -> Bool
    {
        return true
    }

    func getPOSTContents() -> [String:String]
    {
        return [:]
    }

    func handleResponse(_ json: NSDictionary ) -> Bool
    {
        return true
    }

}
