//
//  MetadataCardView.swift
//  SaegAngyeong
//
//  Created by andev on 1/10/26.
//

import UIKit
import SnapKit
import MapKit

final class MetadataCardView: UIView {
    private let headerBackground = UIView()
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let formatLabel = UILabel()
    private let mapView = MKMapView()
    private let noLocationView = UIView()
    private let noLocationImageView = UIImageView()
    private let noLocationLabel = UILabel()
    private let infoStack = UIStackView()
    private let line1Label = UILabel()
    private let line2Label = UILabel()
    private let line3Label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackTurquoise
        layer.cornerRadius = 12

        headerBackground.backgroundColor = .black
        headerBackground.layer.borderWidth = 3
        headerBackground.layer.borderColor = UIColor.blackTurquoise.cgColor
        headerBackground.layer.cornerRadius = 12
        headerBackground.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        addSubview(headerBackground)

        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        headerBackground.addSubview(headerStack)

        titleLabel.font = .pretendard(.bold, size: 14)
        titleLabel.textColor = .deepTurquoise
        formatLabel.font = .pretendard(.bold, size: 12)
        formatLabel.textColor = .deepTurquoise
        formatLabel.text = "EXIF"

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(formatLabel)

        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        addSubview(mapView)

        noLocationView.backgroundColor = .blackTurquoise
        noLocationView.layer.cornerRadius = 12
        noLocationView.layer.borderWidth = 2
        noLocationView.layer.borderColor = UIColor.deepTurquoise.cgColor
        noLocationView.isHidden = true
        addSubview(noLocationView)

        noLocationImageView.image = UIImage(named: "Icon_NoLocation")
        noLocationImageView.tintColor = .deepTurquoise
        noLocationImageView.contentMode = .scaleAspectFit

        noLocationLabel.text = "No Location"
        noLocationLabel.font = .pretendard(.medium, size: 10)
        noLocationLabel.textColor = .deepTurquoise

        noLocationView.addSubview(noLocationImageView)
        noLocationView.addSubview(noLocationLabel)

        infoStack.axis = .vertical
        infoStack.spacing = 6
        addSubview(infoStack)

        line1Label.font = .pretendard(.medium, size: 12)
        line1Label.textColor = .gray75

        line2Label.font = .pretendard(.medium, size: 12)
        line2Label.textColor = .gray75

        line3Label.font = .pretendard(.regular, size: 11)
        line3Label.textColor = .gray75

        [line1Label, line2Label, line3Label].forEach { infoStack.addArrangedSubview($0) }

        headerBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(headerBackground.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(72)
            make.bottom.equalToSuperview().inset(12)
        }

        noLocationView.snp.makeConstraints { make in
            make.edges.equalTo(mapView)
        }

        noLocationImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(26)
        }

        noLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(noLocationImageView.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }

        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(mapView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(mapView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, line1: String, line2: String, line3: String, format: String, latitude: Double?, longitude: Double?) {
        titleLabel.text = title
        line1Label.text = line1
        line2Label.text = line2
        line3Label.text = line3
        line3Label.isHidden = line3.isEmpty
        formatLabel.text = format

        if let lat = latitude, let lon = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 250, longitudinalMeters: 250)
            mapView.setRegion(region, animated: false)
            mapView.removeAnnotations(mapView.annotations)
            mapView.isHidden = false
            noLocationView.isHidden = true
            line3Label.isHidden = line3.isEmpty
        } else {
            mapView.isHidden = true
            noLocationView.isHidden = false
            line3Label.isHidden = true
        }
    }
}
