//
//  PremiumViewController.swift
//  LOL
//
//  Created by Arpit iOS Dev. on 21/08/24.
//

import UIKit
import StoreKit
import TTGSnackbar
import Alamofire

class PremiumViewController: UIViewController, SKPaymentTransactionObserver {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var proFeaturesLabel: UILabel!
    
    let productID = "com.lol.anonymousfeature"
    
    private var premiumSlider: [PremiumModel] = []
    private var currentPage = 0 {
        didSet {
            updateCurrentPage()
        }
    }
    
    private var autoScrollTimer: Timer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.layer.cornerRadius = 28
        view.layer.masksToBounds = true
    }
    
    private var viewModel: PurchaseViewModel!
    
    init(viewModel: PurchaseViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = PurchaseViewModel(apiService: PurchaseApiService.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        adjustForDevice()
        startAutoScroll()
        setupproFeaturesLabel()
        self.unlockButton.layer.cornerRadius = self.unlockButton.frame.height / 2
        unlockButton.frame = CGRect(x: (view.frame.width - 326) / 2, y: view.center.y - 27, width: 326, height: 55)
        self.unlockButton.applyGradient(colors: [UIColor(hex: "#FA4957"), UIColor(hex: "#FD7E41")])
        SKPaymentQueue.default().add(self)
    }
    
    private func setupUI() {
        
        premiumSlider = [
            PremiumModel(id: 1, title: "Reveal Sender Profile",
                         description: "Get hints like their image, location, device, lol id and more...",
                         image: UIImage(named: "Premium_first")!),
            PremiumModel(id: 2, title: "Viewers Hints",
                         description: "Get some funny hint who creates your funny card?",
                         image: UIImage(named: "Premium_Second")!),
            PremiumModel(id: 3, title: "Edit Card Questions",
                         description: "You can edit the card's questions when you ask questions to create a card!",
                         image: UIImage(named: "Premium_Third")!)
        ]
        
        pageControl.numberOfPages = premiumSlider.count
    }
    
    private func updateCurrentPage() {
        pageControl.currentPage = currentPage
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    // MARK: - Purchase Premium Features
    @IBAction func btnUnlockTapped(_ sender: UIButton) {
        if !isConnectedToInternet() {
            let snackbar = TTGSnackbar(message: NSLocalizedString("PremiumNoInternetMessage", comment: ""), duration: .middle)
            snackbar.show()
            return
        }
        if SKPaymentQueue.canMakePayments() {
            let paymentRequest = SKMutablePayment()
            paymentRequest.productIdentifier = productID
            SKPaymentQueue.default().add(paymentRequest)
        } else {
            print("User unable to make payments")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState == .purchased {
                print("Purchase Successfully")
                
                let customAlertVC = CustomAlertViewController()
                customAlertVC.modalPresentationStyle = .overFullScreen
                customAlertVC.modalTransitionStyle = .crossDissolve
                customAlertVC.message = NSLocalizedString("PremiumCongraMessageKey", comment: "")
                customAlertVC.link = NSLocalizedString("PremiumSuccessMessageKey", comment: "")
                customAlertVC.image = UIImage(named: "CopyLink")
                
                self.present(customAlertVC, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        customAlertVC.animateDismissal {
                            customAlertVC.dismiss(animated: false, completion: nil)
                            self.dismiss(animated: true)
                        }
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                viewModel.updatePurchase { result in
                    switch result {
                    case .success(_):
                        print("You have purchased successfully!")
                    case .failure(let error):
                        print("Error : \(error.localizedDescription)")
                    }
                }
                UserDefaults.standard.set(true, forKey: ConstantValue.isPurchase)
                
            } else if transaction.transactionState == .failed {
                let customAlertVC = AlertViewController()
                customAlertVC.modalPresentationStyle = .overFullScreen
                customAlertVC.modalTransitionStyle = .crossDissolve
                customAlertVC.message = NSLocalizedString("PremiumFailedMessageKey", comment: "")
                customAlertVC.link = NSLocalizedString("PremiumFailedPaymentKey", comment: "")
                customAlertVC.image = UIImage(named: "PurchaseFailed")
                
                self.present(customAlertVC, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        customAlertVC.animateDismissal {
                            customAlertVC.dismiss(animated: false, completion: nil)
                        }
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
    
    private func moveToNext() {
        if currentPage < premiumSlider.count - 1 {
            currentPage += 1
        } else {
            currentPage = 0
        }
        let indexPath = IndexPath(item: currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func setupproFeaturesLabel() {
        let fullText = NSLocalizedString("PremiumFeaturesKey", comment: "")
        let attributedString = NSMutableAttributedString(string: fullText)
        let range = (fullText as NSString).range(of: "₹299.00")
        attributedString.addAttribute(.foregroundColor, value: UIColor.red, range: range)
        proFeaturesLabel.attributedText = attributedString
        unlockButton.setTitle(NSLocalizedString("UnlockBtnKey", comment: ""), for: .normal)
    }
    
    private func startAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.moveToNext()
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }
    
    func adjustForDevice() {
        var height: CGFloat = 245
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136, 1334, 1920, 2208:
                height = 205
            case 2436, 1792, 2556, 2532:
                height = 245
            case 2796, 2778, 2688:
                height = 300
            default:
                height = 245
            }
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: height)
        ])
    }
}

//MARK: - UICollectionView DataSource
extension PremiumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return premiumSlider.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PremiumCollectionViewCell", for: indexPath) as! PremiumCollectionViewCell
        cell.setupCell(premiumSlider[indexPath.row])
        return cell
    }
}

//MARK: - UICollectionView Delegates
extension PremiumViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        currentPage = Int(scrollView.contentOffset.x / width)
    }
}

//MARK: - UICollectionView Delegate FlowLayout
extension PremiumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}

