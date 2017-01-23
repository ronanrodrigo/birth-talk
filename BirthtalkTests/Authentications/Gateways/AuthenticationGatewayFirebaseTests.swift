import XCTest
import FirebaseAuth
import Firebase
@testable import Birthtalk

private var isFireAppConfigurated = false

class AuthenticationGatewayFirebaseTests: XCTestCase {

    private let userEmail = "fake@gmail.com"
    private let userName = "Name"
    private let userBirthdate = Date()
    private let userPassword = "somepassword"
    private var firAuth: FIRAuth!
    private var gateway: AuthenticationGateway!

    override func setUp() {
        super.setUp()
        if !isFireAppConfigurated {
            isFireAppConfigurated = true
            FIRApp.configure()
        }
        firAuth = FIRAuth.auth()
        gateway = AuthenticationGatewayFirebase(firAuth: firAuth)
    }

    override func tearDown() {
        super.tearDown()
        guard let firAuth = firAuth, let firAuthCurrentUser = firAuth.currentUser else { return }
        firAuthCurrentUser.delete { error in
            guard let error = error else { return }
            fatalError(error.localizedDescription)
        }
    }

    func testRegisterNewUserAtFirebaseReturnTheUserTroughtResultHandler() {
        let longRunningExpectation = expectation(description: "longRunningFunction")
        var authenticationError: AuthenticationError?
        var createdUser: UserEntity?

        gateway.register(name: userName, email: userEmail, password: userPassword, birthdate: userBirthdate) { result in
            switch result {
            case let .success(user): createdUser = user
            case let .failure(error): authenticationError = error
            }
            longRunningExpectation.fulfill()
        }

        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error)
            XCTAssertNil(authenticationError)
            XCTAssertNotNil(createdUser)
            XCTAssertEqual(self.userName, createdUser?.name)
            XCTAssertEqual(self.userEmail, createdUser?.email)
            XCTAssertEqual(self.userBirthdate, createdUser?.birthdate)
        }
    }

    func testRegisterUserWithAlreadyInUseEmailAtFirebaseReturnEmailAlreadyInUseErrorTroughtResultHandler() {
        let longRunningExpectation = expectation(description: "longRunningFunction")
        var authenticationError: AuthenticationError?
        var createdUser: UserEntity?
        gateway.register(name: userName, email: userEmail, password: userPassword, birthdate: userBirthdate) { _ in }

        gateway.register(name: userName, email: userEmail, password: userPassword, birthdate: userBirthdate) { result in
            switch result {
            case let .success(user): createdUser = user
            case let .failure(error): authenticationError = error
            }
            longRunningExpectation.fulfill()
        }

        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(authenticationError)
            XCTAssertEqual(authenticationError, AuthenticationError.emailAlreadyInUse)
            XCTAssertNil(createdUser)
        }
    }

}