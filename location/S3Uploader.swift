import UIKit
import CoreLocation
import AWSCore
import AWSS3
import AWSDynamoDB

final class S3Uploader {
    static let shared = S3Uploader()
    private let bucket       = "krado-location-images"
    private let regionString = "us-east-1"

    private init() {}

    func upload(image: UIImage,
                deviceId: String,
                coord: CLLocationCoordinate2D,
                completion: @escaping (Result<Void, Error>) -> Void) {

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return completion(.failure(
                NSError(domain: "JPEG", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "JPEG encode failed"])))
        }

        let ts  = Int(Date().timeIntervalSince1970)
        let key = "photos/\(deviceId)/\(ts).jpg"

        guard let tu = AWSS3TransferUtility.s3TransferUtility(forKey: "KradoS3") else {
            return completion(.failure(
                NSError(domain: "S3TU", code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "TransferUtility not found"])))
        }

        // 1) Subir la imagen a S3
        tu.uploadData(
            data,
            bucket:      bucket,
            key:         key,
            contentType: "image/jpeg",
            expression:  nil
        ) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                // 2) Construir la URL pública del objeto en S3
                let resourceUrl = "https://\(self.bucket).s3.\(self.regionString).amazonaws.com/\(key)"  // ← aquí

                // 3) Registrar en DynamoDB, incluyendo resourceUrl
                self.saveRecord(
                    resourceId:     key,
                    resourceUrl: resourceUrl,    // ← aquí
                    deviceId:    deviceId,
                    ts:          ts,
                    lat:         coord.latitude,
                    lon:         coord.longitude,
                    completion:  completion
                )
            }
        }
    }

    private func saveRecord(resourceId: String,
                            resourceUrl: String,    // ← nuevo parámetro
                            deviceId:   String,
                            ts:         Int,
                            lat:        Double,
                            lon:        Double,
                            completion: @escaping (Result<Void, Error>) -> Void) {

        // Crear cada atributo y asignar su valor
        let photoAttr   = AWSDynamoDBAttributeValue(); photoAttr?.s   = resourceId
        let deviceAttr  = AWSDynamoDBAttributeValue(); deviceAttr?.s  = deviceId
        let tsAttr      = AWSDynamoDBAttributeValue(); tsAttr?.n      = "\(ts)"
        let urlAttr     = AWSDynamoDBAttributeValue(); urlAttr?.s     = resourceUrl  // ← aquí

        let attrs: [String: AWSDynamoDBAttributeValue] = [
            "resourceId"    : photoAttr!,
            "deviceId"   : deviceAttr!,
            "timestamp"  : tsAttr!,
            "resourceUrl": urlAttr!                                // ← aquí
        ]

        let put = AWSDynamoDBPutItemInput()!
        put.tableName = "kradoResources"     // ← tu tabla
        put.item      = attrs

        AWSDynamoDB(forKey: "KradoDDB").putItem(put) { _, err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(()))
            }
        }
    }
}
