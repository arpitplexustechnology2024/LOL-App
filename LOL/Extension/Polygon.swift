//
//  Polygon.swift
//  LOL
//
//  Created by Arpit iOS Dev. on 27/08/24.
//

import UIKit

class PolygonImageView: UIImageView {

    // Define the number of sides of the polygon and the border width
    private let sides: Int = 7
    private let borderWidth: CGFloat = 10
    private let borderColor: UIColor = .white

    override func layoutSubviews() {
        super.layoutSubviews()
        applyPolygonMask()
        applyPolygonBorder()
    }

    private func applyPolygonMask() {
        let path = UIBezierPath(polygonIn: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), sides: sides)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

    private func applyPolygonBorder() {
        let path = UIBezierPath(polygonIn: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), sides: sides)
        let border = CAShapeLayer()
        border.path = path.cgPath
        border.lineWidth = borderWidth
        border.strokeColor = borderColor.cgColor
        border.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(border)
    }
}

extension UIBezierPath {
    convenience init(polygonIn rect: CGRect, sides: Int) {
        self.init()
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2
        let angleIncrement = CGFloat.pi * 2 / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = angleIncrement * CGFloat(i) - .pi / 2
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 {
                self.move(to: point)
            } else {
                self.addLine(to: point)
            }
        }
        
        self.close()
    }
}
