import AWSCore
import AWSS3
import AWSDynamoDB
import AWSCognitoIdentityProvider   // trae el credentials provider

enum AWSBootstrap {
    static func configure() {
        // ← REEMPLAZA POR TU ID REAL
        let identityPoolId = "us-east-1:ddddb627-f10a-419c-98de-7cbd767cb408"
        let region: AWSRegionType = .USEast1
        
        // 1) Credenciales “guest” de Cognito
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: region,
            identityPoolId: identityPoolId)
        
        // 2) Configuración base para TODOS los servicios
        let config = AWSServiceConfiguration(
            region: region,
            credentialsProvider: credentialsProvider)!
        AWSServiceManager.default().defaultServiceConfiguration = config
        
        // 3) Registrar utilidades con claves
        AWSS3TransferUtility.register(with: config, forKey: "KradoS3")
        AWSDynamoDB.register(with: config, forKey: "KradoDDB")
        
        print("✅ AWSBootstrap configurado con Cognito")
    }
}
