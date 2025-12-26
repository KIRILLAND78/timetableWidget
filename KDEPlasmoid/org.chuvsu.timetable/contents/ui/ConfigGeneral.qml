import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: configRoot

    property alias cfg_backendUrl: backendUrlField.text
    property alias cfg_group: groupSpinBox.value
    property alias cfg_updateInterval: updateIntervalSpinBox.value
    property alias cfg_transparency: transparencySlider.value

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        GroupBox {
            title: "Подключение"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PlasmaComponents3.Label {
                    text: "URL бэкенда:"
                    font.pointSize: 10
                }

                PlasmaComponents3.TextField {
                    id: backendUrlField
                    Layout.fillWidth: true
                    placeholderText: "http://localhost:5678"
                }

                PlasmaComponents3.Label {
                    text: "Адрес API сервера (обычно http://localhost:5678)"
                    font.pointSize: 8
                    color: "gray"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        GroupBox {
            title: "Расписание"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    PlasmaComponents3.Label {
                        text: "Подгруппа:"
                        font.pointSize: 10
                        Layout.preferredWidth: 120
                    }

                    SpinBox {
                        id: groupSpinBox
                        from: 0
                        to: 10
                        stepSize: 1
                        Layout.fillWidth: true
                    }
                }

                PlasmaComponents3.Label {
                    text: "Номер подгруппы (0 = показывать все подгруппы)"
                    font.pointSize: 8
                    color: "gray"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        GroupBox {
            title: "Обновление"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    PlasmaComponents3.Label {
                        text: "Интервал (сек):"
                        font.pointSize: 10
                        Layout.preferredWidth: 120
                    }

                    SpinBox {
                        id: updateIntervalSpinBox
                        from: 60
                        to: 3600
                        stepSize: 60
                        Layout.fillWidth: true

                        textFromValue: function(value, locale) {
                            if (value >= 60) {
                                return Math.floor(value / 60) + " мин"
                            }
                            return value + " сек"
                        }

                        valueFromText: function(text, locale) {
                            var minutes = parseInt(text)
                            return minutes * 60
                        }
                    }
                }

                PlasmaComponents3.Label {
                    text: "Как часто обновлять расписание автоматически"
                    font.pointSize: 8
                    color: "gray"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        GroupBox {
            title: "Внешний вид"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    PlasmaComponents3.Label {
                        text: "Прозрачность:"
                        font.pointSize: 10
                        Layout.preferredWidth: 120
                    }

                    Slider {
                        id: transparencySlider
                        from: 0
                        to: 100
                        stepSize: 5
                        Layout.fillWidth: true
                    }

                    PlasmaComponents3.Label {
                        text: transparencySlider.value + "%"
                        font.pointSize: 10
                        Layout.preferredWidth: 50
                    }
                }

                PlasmaComponents3.Label {
                    text: "Прозрачность виджета (0 = невидимый, 100 = полностью непрозрачный)"
                    font.pointSize: 8
                    color: "gray"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        PlasmaComponents3.Label {
            text: "После изменения настроек нажмите 'Apply' или 'OK'"
            font.pointSize: 9
            font.italic: true
            color: "gray"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
