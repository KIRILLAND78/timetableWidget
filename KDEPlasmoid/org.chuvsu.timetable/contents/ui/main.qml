import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import "../code/api.js" as API

Item {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    width: 400
    height: 500

    property bool isAuthenticated: false
    property var timetableData: null
    property string currentState: "Loading"
    property int updateInterval: plasmoid.configuration.updateInterval || 300

    // Login dialog
    LoginDialog {
        id: loginDialog
        onLoginSuccess: {
            root.isAuthenticated = true
            statusText.text = "Подключено"
            loadTimetable()
            startUpdateTimer()
        }
        onLoginFailed: function(message) {
            statusText.text = message
        }
    }

    // Update timer
    Timer {
        id: updateTimer
        interval: root.updateInterval * 1000
        running: false
        repeat: true
        onTriggered: loadTimetable()
    }

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header
        PlasmaComponents3.Label {
            id: headerLabel
            text: "Расписание"
            font.pointSize: 14
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        // Day label
        PlasmaComponents3.Label {
            id: dayLabel
            text: "Загрузка..."
            font.pointSize: 10
            color: PlasmaCore.Theme.disabledTextColor
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: PlasmaCore.Theme.highlightColor
            opacity: 0.3
        }

        // Lessons list
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: lessonsList
                model: ListModel { id: lessonsModel }
                spacing: 8

                delegate: Rectangle {
                    width: lessonsList.width
                    height: lessonContent.height + 16
                    color: PlasmaCore.Theme.backgroundColor
                    radius: 8
                    border.color: PlasmaCore.Theme.highlightColor
                    border.width: 1

                    ColumnLayout {
                        id: lessonContent
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        PlasmaComponents3.Label {
                            text: model.discipline
                            font.bold: true
                            font.pointSize: 11
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        PlasmaComponents3.Label {
                            text: model.startTime + " - " + model.endTime + "   " + model.cabinet + "   " + model.type
                            font.pointSize: 9
                            color: PlasmaCore.Theme.disabledTextColor
                            Layout.fillWidth: true
                        }
                    }
                }

                // Empty state
                PlasmaComponents3.Label {
                    anchors.centerIn: parent
                    text: root.isAuthenticated ? "Нет занятий" : "Нажмите для входа"
                    visible: lessonsModel.count === 0
                    font.pointSize: 10
                    font.italic: true
                    color: PlasmaCore.Theme.disabledTextColor
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: PlasmaCore.Theme.highlightColor
            opacity: 0.3
        }

        // Bottom panel
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            PlasmaComponents3.Label {
                id: statusText
                text: "Загрузка..."
                font.pointSize: 8
                font.italic: true
                color: PlasmaCore.Theme.disabledTextColor
                Layout.fillWidth: true
            }

            PlasmaComponents3.Button {
                text: root.isAuthenticated ? "Обновить" : "Войти"
                icon.name: root.isAuthenticated ? "view-refresh" : "system-log-out"
                onClicked: {
                    if (root.isAuthenticated) {
                        loadTimetable()
                    } else {
                        loginDialog.open()
                    }
                }
            }

            PlasmaComponents3.Button {
                text: "Выйти"
                icon.name: "system-log-out"
                visible: root.isAuthenticated
                onClicked: logout()
            }
        }
    }

    // Functions
    function checkAuthStatus() {
        API.setBackendUrl(plasmoid.configuration.backendUrl || "http://localhost:5678")

        API.checkAuthStatus(function(status, response) {
            if (status === 200 && response) {
                try {
                    var data = JSON.parse(response)
                    root.isAuthenticated = data.isAuthenticated

                    if (root.isAuthenticated) {
                        statusText.text = "Подключено"
                        loadTimetable()
                        startUpdateTimer()
                    } else {
                        statusText.text = "Нажмите для входа"
                    }
                } catch (e) {
                    console.error("Failed to parse auth status:", e)
                    statusText.text = "Ошибка"
                }
            } else {
                statusText.text = "Backend недоступен"
            }
        })
    }

    function loadTimetable() {
        API.getTimetable(true, function(status, response) {
            if (status === 200 && response) {
                try {
                    var data = JSON.parse(response)
                    root.timetableData = data
                    renderTimetable(data)
                } catch (e) {
                    console.error("Failed to parse timetable:", e)
                    statusText.text = "Ошибка загрузки"
                }
            } else if (status === 401) {
                root.isAuthenticated = false
                statusText.text = "Требуется авторизация"
                stopUpdateTimer()
            } else {
                statusText.text = "Ошибка соединения"
            }
        })
    }

    function renderTimetable(data) {
        lessonsModel.clear()

        headerLabel.text = "Расписание на " + (data.dayName || "")
        dayLabel.text = data.weekDayName || ""
        statusText.text = data.state || "OK"

        if (data.items && data.items.length > 0) {
            var groupFilter = plasmoid.configuration.group || 0
            var visibleCount = 0

            for (var i = 0; i < data.items.length && visibleCount < 5; i++) {
                var item = data.items[i]

                // Filter by group if set
                if (groupFilter !== 0 && item.subgroup !== 0 && item.subgroup !== groupFilter) {
                    continue
                }

                lessonsModel.append({
                    discipline: item.discipline || "-",
                    startTime: item.startTime || "",
                    endTime: item.endTime || "",
                    cabinet: item.cabinet || "",
                    type: item.type || ""
                })

                visibleCount++
            }

            if (data.items.length > 5) {
                lessonsModel.append({
                    discipline: "+ ещё " + (data.items.length - 5) + " пар",
                    startTime: "",
                    endTime: "",
                    cabinet: "",
                    type: ""
                })
            }
        }
    }

    function logout() {
        API.logout(function(status, response) {
            if (status === 200) {
                root.isAuthenticated = false
                statusText.text = "Вышли из системы"
                lessonsModel.clear()
                stopUpdateTimer()
            }
        })
    }

    function startUpdateTimer() {
        updateTimer.running = true
    }

    function stopUpdateTimer() {
        updateTimer.running = false
    }

    // Initialize on load
    Component.onCompleted: {
        checkAuthStatus()
    }

    // Update when configuration changes
    Connections {
        target: plasmoid.configuration
        function onBackendUrlChanged() {
            API.setBackendUrl(plasmoid.configuration.backendUrl)
            checkAuthStatus()
        }
        function onGroupChanged() {
            if (root.timetableData) {
                renderTimetable(root.timetableData)
            }
        }
        function onUpdateIntervalChanged() {
            root.updateInterval = plasmoid.configuration.updateInterval
            if (updateTimer.running) {
                updateTimer.restart()
            }
        }
    }
}
