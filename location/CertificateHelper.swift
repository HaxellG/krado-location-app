import AWSCore
import AWSIoT

class CertificateHelper {
    static func importCertificate() throws {
        // 1) Verificar que el archivo .p12 exista en el Bundle
        guard let fileUrl = Bundle.main.url(forResource: "deviceCerts", withExtension: "p12") else {
            throw NSError(domain: "No se encontró el archivo .p12", code: -1, userInfo: nil)
        }
        
        // 2) Lanzar error si no puede cargar el contenido
        let pkcs12Data = try Data(contentsOf: fileUrl)

        let success = AWSIoTManager.importIdentity(
            fromPKCS12Data: pkcs12Data,
            passPhrase: "PASS_PHRASE",
            certificateId: "CERTIFICATE_ID"
        )

        // 3) Comprobar estado
        if success {
            print("Certificado importado con exito")
        } else {
            print("Error al importar el certificado")
        }
    }
}
