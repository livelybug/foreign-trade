import { Gateway, X509WalletMixin, InMemoryWallet } from 'fabric-network'
import ccp from '../../../../../first-network/connection-org5'

export const loadCerts = async function _ (zip) {
  try {
    const certNames = []
    let [priKey, pubKey, mspId] = [null, null, null]
    // eslint-disable-next-line no-unused-vars
    let [cerPem, userName] = [null, null]

    const zipFiles = await zip.files
    console.log(zipFiles)

    for (let filename in zipFiles) {
      certNames.push(filename)
      if (certNames.length > 3) throw Error(`Incorrect certificate pack, the number of files inside should be 3, instead of ${certNames.length}`)

      if (filename.endsWith('-priv')) {
        priKey = await zipFiles[filename].async('text')
        console.log(priKey)
      } else if (filename.endsWith('-pub')) {
        pubKey = await zipFiles[filename].async('text')
        console.log(pubKey)
      } else {
        const userInfo = await zipFiles[filename].async('text')
        mspId = JSON.parse(userInfo).mspid
        userName = JSON.parse(userInfo).name
        cerPem = JSON.parse(userInfo).enrollment.identity.certificate
        console.log(mspId)
      }
    }

    if (certNames.length < 3) throw Error(`Incorrect certificate pack, the number of files inside should be 3, instead of ${certNames.length}`)

    console.log(priKey, pubKey, mspId, cerPem, userName)

    if (!(priKey && pubKey && mspId && cerPem && userName)) throw Error('Corrupted certificate pack!')
    console.log(ccp)

    const wallet = new InMemoryWallet()
    await wallet.import(userName, X509WalletMixin.createIdentity(mspId, cerPem, priKey))

    const gateway = new Gateway()
    await gateway.connect(ccp, { wallet, identity: userName, discovery: { enabled: true, asLocalhost: true } })
    const network = await gateway.getNetwork('mychannel')
    const contract = network.getContract('fabcar')
    let result = await contract.evaluateTransaction('queryCar', 'CAR4')
    console.log(`Query CAR12, result is: ${result.toString()}`)
    result = await contract.evaluateTransaction('queryAllCars')
    console.log(`Query all, result is: ${result.toString()}`)
    return true
  } catch (e) {
    return 'Failed to load certificates!'
  }
}
