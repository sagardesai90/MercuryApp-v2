//
//  SettingViewCell.swift
//  Mercury Jacket
//
//  Created by André Ponce on 12/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class SettingViewCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var header: UIView!
    @IBOutlet weak var name_txt: UILabel!
    @IBOutlet weak var table_view: UITableView!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var tableHeight: NSLayoutConstraint!
    @IBOutlet weak var arrow_image: UIImageView!
    @IBOutlet weak var connect_bt: RoundedButton!
    @IBOutlet weak var disconenct_bt: RoundedButton!
    @IBOutlet weak var delete_bt: RoundedButton!
    
    private var bluetoothController :BluetoothController!
    var jacket :Jacket? = nil
    private var settings :[[Any]] = []
    
    private var headerGlass: UIVisualEffectView?
    private var renameButton: UIButton?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.bluetoothController = BluetoothController.getInstance()
        
        table_view.delegate = self
        table_view.dataSource = self

        setupHeaderGlass()
        ensureRenameButton()
    }

    private func setupHeaderGlass() {
        guard let headerView = header else { return }
        let glass = UIView.makeGlassBackground(cornerRadius: 10)
        headerView.insertSubview(glass, at: 0)
        headerView.backgroundColor = .clear
        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: headerView.topAnchor),
            glass.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            glass.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        headerGlass = glass
    }

    private func ensureRenameButton() {
        guard renameButton == nil, let stack = stack else { return }
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Rename device", for: .normal)
        btn.titleLabel?.font = UIFont(name: "FoundersGrotesk-Regular", size: 17) ?? .systemFont(ofSize: 17, weight: .regular)
        btn.setTitleColor(.white, for: .normal)
        btn.contentHorizontalAlignment = .left
        btn.accessibilityLabel = "Rename device"
        btn.accessibilityHint = "Change the display name for this product"
        btn.addTarget(self, action: #selector(renameTapped), for: .touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stack.insertArrangedSubview(btn, at: 0)
        renameButton = btn
    }

    @objc private func renameTapped() {
        presentRenameAlert()
    }

    private func presentRenameAlert() {
        guard let j = jacket else { return }
        let vc = AppController.getContext()
        let alert = UIAlertController(
            title: "Rename device",
            message: "This name is only used in the app.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.text = j.name
            tf.clearButtonMode = .whileEditing
            tf.autocapitalizationType = .words
            tf.returnKeyType = .done
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.applyRenamedName(from: alert)
        })
        vc.present(alert, animated: true)
    }

    private func applyRenamedName(from alert: UIAlertController) {
        guard let j = jacket else { return }
        let raw = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if raw.isEmpty {
            _ = Alert.show(context: AppController.getContext(), message: "Enter a name for the device.")
            return
        }
        if raw.count > 20 {
            _ = Alert.show(context: AppController.getContext(), message: "Max characters 20.")
            return
        }
        j.name = raw
        j.save()
        if AppController.getCurrentJacket()?.id == j.id {
            AppController.connectedTo(jacket: j)
        }
        setJacket(jacket: j)
        SettingsViewController.instance.updateData()
    }
    
    @IBAction func connect_handle(_ sender: Any) {
        let alert = Alert(context: AppController.getContext())
        alert.yesMessage = "Connect"
        alert.noMessage = "Cancel"
        alert.create(message: "Would you like to switch to the \"\(self.jacket!.name)\" jacket?", type: Alert.ASK)
        alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
            if action == Alert.YES_ACTION {
                AppController.connectedTo(jacket: self.jacket)
                BluetoothController.getInstance().connectAllRegistered()
                AppController.startViewController(viewController: AppController.instantiate(id: String(describing: DashBoardViewController.self)))
            }
        }))
        alert.show()
    }

    @IBAction func disconnect_handle(_ sender: Any) {
        let alert: Alert = Alert(context: AppController.getContext())
        alert.yesMessage = "Disconnect"
        alert.noMessage = "Cancel"
        alert.create(message: "Are you sure you want to disconnect \"\(self.jacket!.name)\"?", type: Alert.ASK)
        alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
            if action == Alert.YES_ACTION {
                // Disconnect only this specific device, leave others connected
                if let jacketID = self.jacket?.id {
                    BluetoothController.getInstance().stopConnection(deviceID: jacketID)
                }
                if AppController.getCurrentJacket()?.id == self.jacket?.id {
                    AppController.connectedTo(jacket: nil)
                }
                self.connect_bt.isHidden = false
                self.disconenct_bt.isHidden = true
                SettingsViewController.instance.updateData()

                if AppController.getCurrentJacket() == nil && DashBoardViewController.instance != nil {
                    AppController.removeViewControllerFromStack(view: DashBoardViewController.instance)
                }

                let alert = Alert(context: AppController.getContext())
                alert.confirmMessage = "Continue"
                alert.create(message: String(format: "The Jacket \"%@\" was disconnected.", self.jacket!.name), type: Alert.CONFIRM)
                alert.show()
            }
        }))
        alert.show()
    }

    @IBAction func delete_handle(_ sender: Any) {
        // First confirmation — generic warning
        let alert1: Alert = Alert(context: AppController.getContext())
        alert1.yesMessage = "Continue"
        alert1.noMessage = "Cancel"
        alert1.create(message: "Deleting \"\(self.jacket!.name)\" will remove it from this app and cannot be undone. Are you sure?", type: Alert.ASK)
        alert1.setActionListener(listener: Alert.ActionListener(onActionClick: { (action1) in
            guard action1 == Alert.YES_ACTION else { return }
            // Second confirmation — must explicitly type-confirm intent
            let alert: Alert = Alert(context: AppController.getContext())
            alert.yesMessage = "Yes, Delete"
            alert.noMessage = "Cancel"
            alert.create(message: "This is your final confirmation. \"\(self.jacket!.name)\" will be permanently deleted.", type: Alert.ASK)
            alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
                if action == Alert.YES_ACTION {
                    // Disconnect only this device before removing it from the registry
                    if let jacketID = self.jacket?.id {
                        BluetoothController.getInstance().stopConnection(deviceID: jacketID)
                    }
                    self.jacket?.delete()
                    SettingsViewController.instance.updateData()

                    if AppController.getCurrentJacket() == nil && DashBoardViewController.instance != nil {
                        AppController.removeViewControllerFromStack(view: DashBoardViewController.instance)
                    }

                    let confirmation = Alert(context: AppController.getContext())
                    confirmation.confirmMessage = "Continue"
                    confirmation.create(message: String(format: "The Jacket \"%@\" was deleted.", self.jacket!.name), type: Alert.CONFIRM)
                    confirmation.setActionListener(listener: Alert.ActionListener(onActionClick: { _ in
                        if !AppController.hasJackets() {
                            AppController.startViewController(viewController: AppController.instantiate(id: String(describing: TutorialViewController.self)), clearStack: true)
                        }
                    }))
                    confirmation.show()
                }
            }))
            alert.show()
        }))
        alert1.show()
    }

    func setJacket(jacket: Jacket)
    {
        self.name_txt.text = jacket.dashboardTitleText()
        self.connect_bt.title_txt.text = String(format: "Connect %@", jacket.name)
        self.disconenct_bt.title_txt.text = String(format: "Disconnect %@", jacket.name)
        self.delete_bt.title_txt.text = String(format: "Delete %@", jacket.name)
        
        self.connect_bt.isHidden = AppController.getCurrentJacket() != nil ? jacket.id==AppController.getCurrentJacket()?.id : false
        self.disconenct_bt.isHidden = true//AppController.getCurrentJacket() != nil ? jacket.id != AppController.getCurrentJacket()?.id : true
        
        let isCurrentJacket = AppController.getCurrentJacket() != nil
            && jacket.id == AppController.getCurrentJacket()?.id
        if isCurrentJacket {
            headerGlass?.layer.borderWidth = 1
            headerGlass?.layer.borderColor = UIColor(hexString: "#FA7272").withAlphaComponent(0.4).cgColor
        } else {
            headerGlass?.layer.borderWidth = 0
            headerGlass?.layer.borderColor = UIColor.clear.cgColor
        }
        
        //if(self.jacket == nil)
        //{
            self.jacket = jacket
            self.settings.removeAll()
            let settings = jacket.getSettings()
            let sorted = settings.sorted(by: {$0.0 > $1.0})
            for data in sorted{
                self.settings.append([data.key,data.value])
            }
            tableHeight.constant = CGFloat(self.settings.count*60)
            table_view.layoutIfNeeded()
            self.table_view.reloadData()
        //}
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config :[Any] = self.settings[indexPath.row]
        let cell :SettingLineViewCell = self.table_view.dequeueReusableCell(withIdentifier: "line") as! SettingLineViewCell
        cell.setConfig(jacket: jacket!, key: config[0] as! Int, value: config[1] as! Bool);
        return cell
    }

    public func expand()
    {
        arrow_image.image = UIImage(named: "seta_baixo")
    }
    
    public func retract()
    {
        arrow_image.image = UIImage(named: "seta_cima")
    }
    
}
