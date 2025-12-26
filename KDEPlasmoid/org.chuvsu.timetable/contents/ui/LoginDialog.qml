import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import "../code/api.js" as API

Dialog {
    id: loginDialog

    title: "Авторизация ЧувГУ"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    signal loginSuccess()
    signal loginFailed(string message)

    width: 400
    height: 250

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        PlasmaComponents3.Label {
            text: "Вход в систему Мой ЧувГУ"
            font.pointSize: 12
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        PlasmaComponents3.Label {
            text: "Email:"
            font.pointSize: 10
        }

        PlasmaComponents3.TextField {
            id: emailField
            placeholderText: "student@example.com"
            Layout.fillWidth: true
            focus: true

            Keys.onReturnPressed: {
                if (passwordField.text.length > 0) {
                    loginDialog.accept()
                } else {
                    passwordField.forceActiveFocus()
                }
            }
        }

        PlasmaComponents3.Label {
            text: "Пароль:"
            font.pointSize: 10
        }

        PlasmaComponents3.TextField {
            id: passwordField
            placeholderText: "••••••••"
            echoMode: TextInput.Password
            Layout.fillWidth: true

            Keys.onReturnPressed: {
                if (emailField.text.length > 0) {
                    loginDialog.accept()
                }
            }
        }

        PlasmaComponents3.Label {
            id: errorLabel
            text: ""
            color: "red"
            font.pointSize: 9
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            PlasmaComponents3.Label {
                text: "Соглашение:"
                font.pointSize: 8
                color: Kirigami.Theme.disabledTextColor
            }

            PlasmaComponents3.Label {
                text: "<a href='https://online.chuvsu.ru/doc/user_agreement'>Условия</a>"
                font.pointSize: 8
                onLinkActivated: Qt.openUrlExternally(link)
            }

            PlasmaComponents3.Label {
                text: "<a href='https://online.chuvsu.ru/doc/privacy_policy'>Конфиденциальность</a>"
                font.pointSize: 8
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }

    onAccepted: {
        var email = emailField.text.trim()
        var password = passwordField.text

        if (!email || !password) {
            errorLabel.text = "Заполните все поля"
            loginDialog.open()
            return
        }

        errorLabel.text = "Вход..."

        API.login(email, password, function(status, response) {
            if (status === 200 && response) {
                try {
                    var result = JSON.parse(response)
                    if (result.success) {
                        emailField.text = ""
                        passwordField.text = ""
                        errorLabel.text = ""
                        loginSuccess()
                    } else {
                        errorLabel.text = result.message || "Ошибка входа"
                        loginDialog.open()
                        loginFailed(result.message || "Ошибка входа")
                    }
                } catch (e) {
                    errorLabel.text = "Ошибка обработки ответа"
                    loginDialog.open()
                    loginFailed("Ошибка обработки ответа")
                }
            } else {
                errorLabel.text = "Ошибка соединения с сервером"
                loginDialog.open()
                loginFailed("Ошибка соединения")
            }
        })
    }

    onRejected: {
        emailField.text = ""
        passwordField.text = ""
        errorLabel.text = ""
    }

    onOpened: {
        emailField.forceActiveFocus()
    }
}
