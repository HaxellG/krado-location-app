import AWSCore
import AWSS3
import AWSDynamoDB
import AWSCognitoIdentityProvider

enum AWSBootstrap {
    static func configure() {
        // 1) Configuración del Pool
        let identityPoolId = "POOL_IDENTIFIER"
        let region: AWSRegionType = .USEast1
        
        // 2) Credenciales de Cognito
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: region,
            identityPoolId: identityPoolId)
        
        // 3) Configuración base
        let config = AWSServiceConfiguration(
            region: region,
            credentialsProvider: credentialsProvider)!
        AWSServiceManager.default().defaultServiceConfiguration = config
        
        // 4) Registrar utilidades con claves
        AWSS3TransferUtility.register(with: config, forKey: "S3")
        AWSDynamoDB.register(with: config, forKey: "DDB")
        
        print("✅ AWSBootstrap configurado con Cognito")
    }
}
