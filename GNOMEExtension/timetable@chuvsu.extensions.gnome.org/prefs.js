import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import Gio from 'gi://Gio';

import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class TimetablePreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        // Create a preferences page
        const page = new Adw.PreferencesPage({
            title: 'Настройки',
            icon_name: 'dialog-information-symbolic',
        });
        window.add(page);

        // Connection group
        const connectionGroup = new Adw.PreferencesGroup({
            title: 'Подключение',
            description: 'Настройки подключения к API бэкенда',
        });
        page.add(connectionGroup);

        // Backend URL
        const backendRow = new Adw.EntryRow({
            title: 'URL бэкенда',
        });
        settings.bind(
            'backend-url',
            backendRow,
            'text',
            Gio.SettingsBindFlags.DEFAULT
        );
        connectionGroup.add(backendRow);

        // Timetable group
        const timetableGroup = new Adw.PreferencesGroup({
            title: 'Расписание',
            description: 'Настройки отображения расписания',
        });
        page.add(timetableGroup);

        // Group filter
        const groupRow = new Adw.SpinRow({
            title: 'Подгруппа',
            subtitle: 'Номер подгруппы (0 = все подгруппы)',
            adjustment: new Gtk.Adjustment({
                lower: 0,
                upper: 10,
                step_increment: 1,
            }),
        });
        settings.bind(
            'group',
            groupRow,
            'value',
            Gio.SettingsBindFlags.DEFAULT
        );
        timetableGroup.add(groupRow);

        // Update group
        const updateGroup = new Adw.PreferencesGroup({
            title: 'Обновление',
            description: 'Настройки автоматического обновления',
        });
        page.add(updateGroup);

        // Update interval
        const intervalRow = new Adw.SpinRow({
            title: 'Интервал обновления',
            subtitle: 'Как часто обновлять расписание (в секундах)',
            adjustment: new Gtk.Adjustment({
                lower: 60,
                upper: 3600,
                step_increment: 60,
            }),
        });
        settings.bind(
            'update-interval',
            intervalRow,
            'value',
            Gio.SettingsBindFlags.DEFAULT
        );
        updateGroup.add(intervalRow);

        // About group
        const aboutGroup = new Adw.PreferencesGroup({
            title: 'О расширении',
        });
        page.add(aboutGroup);

        const aboutRow = new Adw.ActionRow({
            title: 'ЧувГУ Расписание',
            subtitle: 'Версия 1.0.0\n\nАвтор: Казаков Кирилл Валерьевич, КТ-31-21\nAPI: Петрянкин Даниил Евгеньевич, КТ-31-21\nДизайн: Гаврилов Александр Сергеевич, КТ-42-20',
        });
        aboutGroup.add(aboutRow);
    }
}
