import AWSCore
import AWSS3
import AWSDynamoDB
import AWSCognitoIdentityProvider

enum AWSBootstrap {
    static func configure() {
        let identityPoolId = "us-east-1:01939ee7-dd52-4145-a62c-d607af9272ee"
        let region: AWSRegionType = .USEast1
        
        // 1) Credenciales de Cognito
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: region,
            identityPoolId: identityPoolId)
        
        // 2) Configuración base
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
