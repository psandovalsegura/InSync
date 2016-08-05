//
//  Queue.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/11/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import Foundation

class QNode<T> {
    var value: T
    var next: QNode?
    
    init(item:T) {
        value = item
    }
}


struct Queue<T> {
    private var top: QNode<T>!
    private var bottom: QNode<T>!
    
    init() {
        top = nil
        bottom = nil
    }
    
    mutating func enQueue(item: T) {
        
        let newNode:QNode<T> = QNode(item: item)
        
        if top == nil {
            top = newNode
            bottom = top
            return
        }
        
        bottom.next = newNode
        bottom = newNode
    }
    
    mutating func deQueue() -> T? {
        
        let topItem: T? = top?.value
        if topItem == nil {
            return nil
        }
        
        if let nextItem = top.next {
            top = nextItem
        } else {
            top = nil
            bottom = nil
        }
        
        return topItem
    }
    
    func isEmpty() -> Bool {
        
        return top == nil ? true : false
    }
    
    func peek() -> T? {
        return top?.value
    }
    
}

// usage
//var q = Queue<String>()
//
//q.enQueue("aaaa")
//q.enQueue("bbbb")
//q.enQueue("cccc")
//
//var a = q.deQueue()
//var b = q.deQueue()
//var c = q.deQueue()
//c = q.deQueue()
//q.enQueue("dddd")
//q.enQueue("eeee")
//
//
//var z = q.peek()
//var empty = q.isEmpty()
//
//var p = Queue<String?>()
//p.enQueue(nil)
//
////var aa = p.deQueue()
//
//var zz = p.peek()
//var empty2 = p.isEmpty()