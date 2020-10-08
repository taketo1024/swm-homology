//
//  SimpleDirectedGraph.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2020/10/08.
//

import Foundation

public struct SimpleDirectedGraph {
    public typealias VertexId = Int
    public typealias GroupId = Int
    
    public struct Vertex: Encodable {
        public let id: Int
        public let label: String
        public let group: Int
    }
    
    public struct Edge: Encodable {
        public let from: VertexId
        public let to: VertexId
        public let label: String?
        public let dashes: Bool
    }
    
    public private(set) var vertices: [Vertex]
    public private(set) var edges: [Edge]
    private var count = 0

    public init() {
        self.vertices = []
        self.edges = []
    }
    
    @discardableResult
    public mutating func addVertex(label: String, group: GroupId? = nil) -> VertexId {
        count += 1
        let v = Vertex(id: count, label: label, group: group ?? 0)
        vertices.append(v)
        return v.id
    }
    
    public mutating func removeVertex(id: VertexId) {
        edges.removeAll { e in
            e.from == id || e.to == id
        }
        if let index = vertices.firstIndex(where: { $0.id == id }) {
            vertices.remove(at: index)
        }
    }
    
    public mutating func addEdge(from: VertexId, to: VertexId, label: String? = nil, dashes: Bool = false) {
        let e = Edge(from: from, to: to, label: label, dashes: dashes)
        edges.append(e)
    }
    
    public mutating func removeEdge(from: VertexId, to: VertexId) {
        // TODO
    }
    
    public func asHTML(title: String? = nil) -> String {
        let template =
"""
<!doctype html>
<html>
<head>
  <title>${title}</title>
  <script type="text/javascript" src="https://visjs.github.io/vis-network/standalone/umd/vis-network.min.js"></script>
  <style type="text/css">
    #mynetwork {
      width: 100%;
      height: 100vh;
      border: 1px solid lightgray;
    }
  </style>
</head>
<body>

<div id="mynetwork"></div>

<script type="text/javascript">
  var nodes = new vis.DataSet(${vertices});
  var edges = new vis.DataSet(${edges});

  // create a network
  var container = document.getElementById('mynetwork');
  var data = {
    nodes: nodes,
    edges: edges
  };
  var options = {
    edges: {
      arrows: "to"
    },
    layout: {
      improvedLayout: false,
      hierarchical: {
        enabled: true,
        direction: "UD",
        sortMethod: "directed",
      }
    }
  };
  var network = new vis.Network(container, data, options);
</script>
</body>
</html>
"""
        let html =
            template
                .replacingOccurrences(of: "${title}", with: title ?? "graph")
                .replacingOccurrences(of: "${vertices}", with: vertices.asJSON())
                .replacingOccurrences(of: "${edges}", with: edges.asJSON())
        return html
    }
    
    public func showHTML(title: String? = nil) {
        let html = asHTML(title: title)

        if #available(OSX 10.12, *) {
            let file = FileManager().temporaryDirectory.appendingPathComponent("tmp.html")
            try! html.write(to: file, atomically: true, encoding: .utf8)
            print(file)

            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [file.absoluteString]
            task.launch()
        } else {
            // Fallback on earlier versions
        }

    }
}
