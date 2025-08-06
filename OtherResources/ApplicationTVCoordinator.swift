import AdSupport
import AppsFlyerLib
import AppTrackingTransparency
import Combine
import Foundation
import Kingfisher
import SwiftUI
import UIKit

class ApplicationTVCoordinator: NSObject, Coordinator, StartupTVCoordinatorDelegate, ActivateTVCoordinatorDelegate, MenuTVCoordinatorDelegate {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var apiService: APIService = Config.apiService

    private var appSettings: Settings?
    private var appSession: AppSessionManager?
    private var splashViewModel: SplashViewModel!

    private var deepLinkRoute: URL?
    private var deepLinkRouter: DeepLinkRouter = .init()

    private var shouldWaitForVideo: Bool = true

    private weak var menuCoordinator: MenuTVCoordinator?

    var menuLoaderService = MenuLoaderService.shared

    private var cancellables = Set<AnyCancellable>()

    private var isMenuCreated: Bool {
        self.menuCoordinator != nil
    }

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()

        self.addObservers()
    }

    func start(withVideoSplash hasVideo: Bool) {
        ImageCache.default.diskStorage.config.expiration = .days(30)

        self.deepLinkRouter.delegate = self

        if hasVideo, let currentAppVersion = Bundle.main.releaseVersionNumber,
           !UserDefaults.standard.wasVideoPlayed(forAppVersion: currentAppVersion)
        {
            self.showVideoSplash()
            UserDefaults.standard.setVideoPlayedAppVersion(value: currentAppVersion)
        } else {
            self.shouldWaitForVideo = false
            self.showStaticSplash()
        }

        self.showSplashScreen()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.authorizeUser),
                                               name: Notification.Name.User.shouldReauthorize,
                                               object: nil)
    }

    func showStartupScreen(shouldPresent: Bool = true) {
        let startupCoordinator = StartupTVCoordinator(navigationController: navigationController)
        addChildCoordinator(startupCoordinator)
        startupCoordinator.delegate = self
        startupCoordinator.start(shouldPresent: shouldPresent)
    }

    @objc func showChurnScreen() {
        let coordinator = TVChooseYourPlanCoordinator(navigationController: self.navigationController)
        coordinator.delegate = self
        self.addChildCoordinator(coordinator)
        coordinator.start()
    }

    private func showStaticSplash() {
        let storyboard = UIStoryboard(name: "Splash", bundle: nil)
        let splashViewController = storyboard.instantiateViewController(withIdentifier: SplashTVViewController.className) as! SplashTVViewController
        self.navigationController.setViewControllers([splashViewController], animated: false)
    }

    private func loadStoreProducts() {
        SubscribeManager.shared.startMonitoring()
    }

    func checkAppVersion() {
        if let settings = self.appSettings,
           settings.isAppUpToDate == false,
           ExternalServices.appStoreURL.isEmpty == false
        {
            self.showForceUpdateAlert()
        }
    }

    private func showVideoSplash() {
        let viewController = SplashVideoViewController.newViewController()
        viewController.providesPresentationContextTransitionStyle = true
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.didFinishPlay = { [weak self] in
            guard let self else { return }
            self.shouldWaitForVideo = false
            self.showStartupOrMainMenu()
        }

        self.navigationController.setViewControllers([viewController], animated: false)
    }

    private func showStartupOrMainMenu() {
        DispatchQueue.main.async {
            guard let session = self.appSession else {
                let storyboard = UIStoryboard(name: "Splash", bundle: nil)
                let splashViewController = storyboard.instantiateViewController(withIdentifier: SplashTVViewController.className) as! SplashTVViewController
                self.navigationController.setViewControllers([splashViewController], animated: false)
                return
            }

            if session.hasUser {
                self.showMainMenu()
            } else {
                Settings.current()?.hasHomeExperiment == true ? self.showMainMenu() : self.showStartupScreen(shouldPresent: false)
            }

            self.checkAppVersion()
            self.loadStoreProducts()
        }
    }

    private func showSplashScreen() {
        let didCompleteSetupCallback: ((InitialSetupState) -> Void)? = { [weak self] setupResult in
            guard let self else { return }

            switch setupResult {
            case let .failure(errorMessage: errorMessage), let .noNetworkConnection(errorMessage: errorMessage):
                DispatchQueue.main.async {
                    self.showAlert(with: errorMessage)
                }
            case let .success(session: session, settings: settings):
                self.appSession = session
                self.appSettings = settings

                DispatchQueue.main.async {
                    if let routeURL = self.deepLinkRoute {
                        self.deepLinkRouter.handle(url: routeURL)
                    } else if !self.shouldWaitForVideo {
                        self.showStartupOrMainMenu()
                    }
                }
            }
        }

        self.splashViewModel = SplashViewModel(apiService: self.apiService, didCompleteSetupCallback: didCompleteSetupCallback)
        Task { @MainActor [weak self] in
            await self?.splashViewModel.tryToConnect()
        }
    }

    @objc func authorizeUser() {
        self.appSession?.logoutUser() // Make sure we cleanup any remaining user data
        self.menuCoordinator?.showHome()
    }

    private func showAlert(with message: String) {
        let alert = UIAlertController(title: AppStrings.Alerts.generalErrorTitle.localized(), message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: AppStrings.Alerts.retryButtonTitle.localized(), style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.start(withVideoSplash: false)
        })
        alert.addAction(retryAction)

        #if QA_BUILD
            let envSetupAction = UIAlertAction(title: "Environment setup", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self.presentEnvironmentSetup()
            })
            alert.addAction(envSetupAction)
        #endif

        self.navigationController.present(alert, animated: true, completion: nil)
    }

    private func presentEnvironmentSetup() {
        #if QA_BUILD
            let envSetupView = TVEnvironmentSetupView()
            let viewController = UIHostingController(rootView: envSetupView)
            let navController = UINavigationController(rootViewController: viewController)
            self.navigationController.present(navController, animated: true, completion: nil)
        #endif
    }

    private func showForceUpdateAlert() {
        let alert = UIAlertController(title: AppStrings.Alerts.ForceUpdate.warningTitle.localized(),
                                      message: AppStrings.Alerts.ForceUpdate.warningMessage.localized(),
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: AppStrings.Alerts.okButtonTitle.localized(), style: .default, handler: { _ in
            if let url = URL(string: ExternalServices.appStoreURL) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        alert.addAction(okAction)
        self.navigationController.present(alert, animated: true, completion: nil)
    }

    func areMenusEqual(firstMenu: [AppSection], secondMenu: [AppSection]) -> Bool {
        let menuPairs = zip(firstMenu, secondMenu).enumerated()
        let result = menuPairs.filter { $1.0.title == $1.1.title }
            .filter { $1.0.name == $1.1.name }.count
        return result == firstMenu.count
    }

    func showMainMenu(shouldCheckEntitlement: Bool = false) {
        guard !self.isMenuCreated else {
            self.startMenuCoordinator(shouldCheckEntitlement: shouldCheckEntitlement)
            return // Menu already presented
        }

        if let existingCoordinator = self.menuCoordinator {
            self.removeChildCoordinator(existingCoordinator)
        }

        let menuCoordinator = MenuTVCoordinator(navigationController: self.navigationController)
        menuCoordinator.delegate = self
        self.addChildCoordinator(menuCoordinator)
        self.menuCoordinator = menuCoordinator
        self.startMenuCoordinator(shouldCheckEntitlement: shouldCheckEntitlement)
    }

    private func startMenuCoordinator(shouldCheckEntitlement: Bool = false) {
        self.menuCoordinator?.start()

        if shouldCheckEntitlement {
            self.checkUnentitledUser()
        } else if AppSessionManager.shared.hasUser {
            self.checkATT()
        }
    }

    func setupRedirectRoute(routeURL: URL) {
        if self.appSession != nil {
            self.deepLinkRouter.handle(url: routeURL)
        } else {
            self.deepLinkRoute = routeURL
        }
    }

    private func checkUnentitledUser() {
        if let user = AppSessionManager.shared.user, user.canPurchaseSubscription == true {
            let event = StartUpEvent(type: .loginPage)
            AnalyticsManager.shared.log(event)

            self.showChurnScreen()
        }
    }

    func checkATT() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            guard let self else { return }
            self.trackAppsflyerId()
        }
    }

    private func trackAppsflyerId() {
        let appsflyerId = AppsFlyerLib.shared().getAppsFlyerUID()

        let idfa = ASIdentifierManager.provideIdentifierForAdvertisingIfAvailable()
        let appId = ExternalServices.appStoreId

        let trackRoute = APIRoute.trackAppsflyer(appsflyerId: appsflyerId, advertisingId: idfa, appId: appId)
        self.apiService.makeAPICall(route: trackRoute) { _, _ in }
    }

    // MARK: StartupTVCoordinator

    func startupCoordinatorDidSelectBrowse(sender: StartupTVCoordinator) {
        self.showMainMenu()
        self.removeChildCoordinator(sender)
    }

    func startupCoordinatorDidClosed(sender: StartupTVCoordinator) {
        self.showMainMenu()
        self.removeChildCoordinator(sender)
    }

    func startupCoordinatorDidAuthenticate(sender: StartupTVCoordinator, screenType: StartupScreenType) {
        if self.navigationController.presentedViewController != nil {
            self.navigationController.dismiss(animated: true, completion: {
                self.presentMainMenu(screenType: screenType)
            })
        } else {
            self.presentMainMenu(screenType: screenType)
        }

        self.removeChildCoordinator(sender)
    }

    private func presentMainMenu(screenType: StartupScreenType) {
        let shouldCheckEntitlements = screenType == .subscribe
        self.showMainMenu(shouldCheckEntitlement: shouldCheckEntitlements)
    }

    func startupDidSetAsTopView(sender _: StartupTVCoordinator) {
        if let menuCoordinator {
            self.removeChildCoordinator(menuCoordinator)
        }
    }

    // MARK: - ActivateTVCoordinatorDelegate

    func coordinatorDidAuthenticate(coordinator: ActivateTVCoordinator) {
        let event = StartUpEvent(type: .successPage)
        AnalyticsManager.shared.log(event)

        self.navigationController.dismiss(animated: true, completion: nil)

        self.showMainMenu(shouldCheckEntitlement: true)
        self.removeChildCoordinator(coordinator)
    }

    func coordinatorDidCancelAuthentication(coordinator: ActivateTVCoordinator) {
        self.removeChildCoordinator(coordinator)
    }

    // MARK: - MenuTVCoordinatorDelegate

    func coordinatorDidLogOut(coordinator _: MenuTVCoordinator) {
        self.menuCoordinator?.showHome()
    }

    func coordinatorShouldAuthenticate(navigationController _: UINavigationController) {
        let coordinator = self.buildAuthenticateCoordinator()
        coordinator.start()
    }
}

extension ApplicationTVCoordinator: DeepLinkRouterDelegate {
    func navigateToSeriesAndPlayEpisode(seriesIdentifier: String, mediaIdentifier: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showMainMenu()
            self.menuCoordinator?.playEpisode(seriesIdentifier: seriesIdentifier, episodeIdentifier: mediaIdentifier)
        }
    }

    func navigateToMovie(identifier: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showMainMenu()
            self.menuCoordinator?.showContent(type: .movie, identifier: identifier)
        }
    }

    func navigateToSeries(identifier: String, seasonNumber _: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showMainMenu()
            self.menuCoordinator?.showContent(type: .series, identifier: identifier)
        }
    }

    func navigateToEpisode(identifier: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showMainMenu()
            self.menuCoordinator?.showContent(type: .episode, identifier: identifier)
        }
    }

    func playEpisode(identifier: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showMainMenu()
            self.menuCoordinator?.playContent(type: .episode, identifier: identifier)
        }
    }

    func playMovie(identifier: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showMainMenu()
            self.menuCoordinator?.playContent(type: .movie, identifier: identifier)
        }
    }

    func playExtra(identifier: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let route = APIRoute.playExtra(identifier: identifier)
            self.apiService.createAPICall(route: route) { [weak self] (result: Result<Movie, Error>) in
                guard let self else { return }

                switch result {
                case let .success(value):
                    let media = value
                    media.type = .video
                    self.playMedia(media: media)
                case .failure:
                    break
                }
            }
        }
    }

    private func playMedia(media: Movie) {
        let playCoordinator = PlayTVCoordinator.shared
        playCoordinator.setup(navigationController: self.navigationController)
        playCoordinator.mediaToPlay = media
        playCoordinator.start()
    }

    func navigateToLiveTV() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismissPresentedController()

            if self.menuCoordinator == nil {
                self.showMainMenu()
            }
            self.menuCoordinator?.showLiveTV()
        }
    }

    func navigateToLiveTV(toChannel channel: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismissPresentedController()

            if self.menuCoordinator == nil {
                self.showMainMenu()
            }
            self.menuCoordinator?.showLiveTV(withChannel: channel)
        }
    }

    private func dismissPresentedController() {
        if self.navigationController.presentedViewController != nil {
            self.navigationController.dismiss(animated: false, completion: nil)
        }
    }

    func playMovieTrailer(identifier _: String) {
        // Not yet supported for tvOS
    }

    func playSeriesTrailer(identifier _: String) {
        // Not yet supported for tvOS
    }

    func navigateToActivateTV(code _: String?) {
        // Not yet supported for tvOS
    }

    func navigateToCollection(identifier _: String) {
        // Not yet supported for tvOS
    }

    func navigateToSettings() {
        // Not yet supported for tvOS
    }

    func navigateToHelp() {
        // Not yet supported for tvOS
    }

    func navigateToDownloads() {
        // Not yet supported for tvOS
    }

    func navigateToMyList() {
        // Not yet supported for tvOS
    }

    func navigateToStartup() {
        // Not yet supported for tvOS
    }

    func navigateToHome() {
        // Not yet supported for tvOS
    }

    func navigateToConnectTV() {
        // Not yet supported for tvOS
    }

    func navigateToMovies(genre _: String?) {
        // Not yet supported for tvOS
    }

    func navigateToOriginals(category _: String?) {
        // Not yet supported for tvOS
    }

    func navigateToSearch() {
        // Not yet supported for tvOS
    }

    func navigateToOffer(identifier _: String) {
        // Not yet supported for tvOS
    }

    func navigateToChooseYourPlan() {
        // Not yet supported for tvOS
    }

    func queueEpisode(identifier _: String) {
        // Not yet supported for tvOS
    }

    func queueMovie(identifier _: String) {
        // Not yet supported for tvOS
    }

    func playSeries(identifier _: String, seasonNumber _: String?) {
        // Not yet supported for tvOS
    }

    func enablePush() {
        // Not yet supported for tvOS
    }
}

extension ApplicationTVCoordinator: TVChooseYourPlanCoordinatorDelegate {
    func offerSelectionBackPress(_ sender: TVChooseYourPlanCoordinator) {
        self.removeChildCoordinator(sender)
    }

    func offerSelectionCanceled(coordinator: TVChooseYourPlanCoordinator) {
        self.removeChildCoordinator(coordinator)
    }

    func offerSelectionSubscribeSuccessful(sender: TVChooseYourPlanCoordinator) {
        self.removeChildCoordinator(sender)
    }

    func offerSelectionFinishPurchaseFlow(_: TVChooseYourPlanCoordinator) {
        self.checkATT()
    }
}

extension ApplicationTVCoordinator: AuthenticateTVCoordinatorDelegate {
    func buildAuthenticateCoordinator(initialState: AuthenticateInitialState = .login) -> AuthenticateTVCoordinator {
        let coordinator = AuthenticateTVCoordinator(navigationController: self.navigationController)
        self.addChildCoordinator(coordinator)
        coordinator.delegate = self
        coordinator.initialState = initialState
        return coordinator
    }

    func authenticateCoordinatorDidAuthenticate(sender: AuthenticateTVCoordinator, screenType _: StartupScreenType) {
        self.removeChildCoordinator(sender)
        self.navigationController.dismiss(animated: false, completion: nil)

        let event = StartUpEvent(type: .successPage)
        AnalyticsManager.shared.log(event)
    }

    func authenticateCoordinatorDidCancelAuthenticate(sender: AuthenticateTVCoordinator) {
        self.removeChildCoordinator(sender)
    }
}
