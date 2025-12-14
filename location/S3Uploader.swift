import UIKit
import CoreLocation
import AWSCore
import AWSS3
import AWSDynamoDB

final class S3Uploader {
    static let shared = S3Uploader()
    private let bucket       = "BUCKET-NAME"
    private let regionString = "us-east-1"

    private init() {}

    func upload(
        image: UIImage,
        deviceId: String,
        coord: CLLocationCoordinate2D,
        altitude: Double,
        title: String,
        description: String,
        tag: String,                     // ← nuevo parámetro
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 1) Convertir UIImage a JPEG
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            let err = NSError(
                domain: "S3Uploader",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "JPEG conversion failed"]
            )
            return completion(.failure(err))
        }

        // 2) Generar clave única en S3
        let ts  = Int(Date().timeIntervalSince1970)
        let key = "photos/\(deviceId)/\(ts).jpg"

        // 3) Obtener la TransferUtility registrada desde AWSBootstrap
        guard let tu = AWSS3TransferUtility.s3TransferUtility(forKey: "KradoS3") else {
            let err = NSError(
                domain: "S3Uploader",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "TransferUtility not found"]
            )
            return completion(.failure(err))
        }

        // 4) Subir a S3
        tu.uploadData(
            data,
            bucket:      bucket,
            key:         key,
            contentType: "image/jpeg",
            expression:  nil
        ) { _, error in
            if let error = error {
                return completion(.failure(error))
            }

            // 5) Construir la URL pública del objeto en S3
            let resourceUrl =
                "https://\(self.bucket).s3.\(self.regionString).amazonaws.com/\(key)"

            // 6) Registrar en DynamoDB, pasando altitud, título, descripción y tag
            self.saveRecord(
                resourceId:  key,
                resourceUrl: resourceUrl,
                deviceId:    deviceId,
                ts:          ts,
                lat:         coord.latitude,
                lon:         coord.longitude,
                alt:         altitude,
                title:       title,
                description: description,
                tag:         tag,
                completion:  completion
            )
        }
    }

    private func saveRecord(
        resourceId:  String,
        resourceUrl: String,
        deviceId:    String,
        ts:          Int,
        lat:         Double,
        lon:         Double,
        alt:         Double,
        title:       String,
        description: String,
        tag:         String,             // ← aquí
        completion:  @escaping (Result<Void, Error>) -> Void
    ) {
        // Crear cada atributo y asignar su valor
        let idAttr        = AWSDynamoDBAttributeValue(); idAttr?.s         = resourceId
        let urlAttr       = AWSDynamoDBAttributeValue(); urlAttr?.s        = resourceUrl
        let deviceAttr    = AWSDynamoDBAttributeValue(); deviceAttr?.s     = deviceId
        let tsAttr        = AWSDynamoDBAttributeValue(); tsAttr?.n         = "\(ts)"
        let latAttr       = AWSDynamoDBAttributeValue(); latAttr?.n        = "\(lat)"
        let lonAttr       = AWSDynamoDBAttributeValue(); lonAttr?.n        = "\(lon)"
        let altAttr       = AWSDynamoDBAttributeValue(); altAttr?.n        = "\(alt)"
        let titleAttr     = AWSDynamoDBAttributeValue(); titleAttr?.s      = title
        let descAttr      = AWSDynamoDBAttributeValue(); descAttr?.s       = description
        let tagAttr       = AWSDynamoDBAttributeValue(); tagAttr?.s        = tag      // ← aquí

        // Construir el diccionario de atributos
        let attrs: [String: AWSDynamoDBAttributeValue] = [
            "resourceId"  : idAttr!,
            "resourceUrl" : urlAttr!,
            "deviceId"    : deviceAttr!,
            "timestamp"   : tsAttr!,
            "latitude"    : latAttr!,
            "longitude"   : lonAttr!,
            "altitude"    : altAttr!,
            "title"       : titleAttr!,
            "description" : descAttr!,
            "tag"         : tagAttr!
        ]

        let put = AWSDynamoDBPutItemInput()!
        put.tableName = "kradoResources"
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
