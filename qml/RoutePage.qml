/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2014 Osmo Salomaa
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "."

Page {
    id: page
    allowedOrientations: Orientation.All
    canNavigateForward: page.from && page.to
    property var from: null
    property string fromText: "From"
    property var to: null
    property string toText: "To"
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: parent.width
        Column {
            id: column
            anchors.fill: parent
            property var settings: null
            PageHeader { title: "Find Route" }
            ValueButton {
                id: usingButton
                label: "Using"
                height: Theme.itemSizeSmall
                value: py.evaluate("poor.app.router.name")
                width: parent.width
                onClicked: {
                    var dialog = app.pageStack.push("RouterPage.qml");
                    dialog.accepted.connect(function() {
                        usingButton.value = py.evaluate("poor.app.router.name");
                        column.addSetttings();
                    })
                }
            }
            ListItem {
                id: fromItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    color: fromItem.highlighted ?
                        Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    text: page.fromText
                }
                onClicked: {
                    var dialog = app.pageStack.push("RoutePointPage.qml");
                    dialog.accepted.connect(function() {
                        page.fromText = dialog.query;
                    })
                }
            }
            ListItem {
                id: toItem
                contentHeight: Theme.itemSizeSmall
                ListItemLabel {
                    color: toItem.highlighted ?
                        Theme.highlightColor : Theme.primaryColor
                    height: Theme.itemSizeSmall
                    text: page.toText
                }
                onClicked: {
                    var dialog = app.pageStack.push("RoutePointPage.qml");
                    dialog.accepted.connect(function() {
                        page.toText = dialog.query;
                    })
                }
            }
            Component.onCompleted: column.addSetttings();
            function addSetttings() {
                // Add router-specific settings from router's own QML file.
                column.settings && column.settings.destroy();
                var uri = py.evaluate("poor.app.router.settings_qml_uri");
                if (!uri) return;
                var component = Qt.createComponent(uri);
                column.settings = component.createObject(column);
                column.settings.anchors.left = column.left;
                column.settings.anchors.right = column.right;
                column.settings.width = column.width;
            }
        }
        VerticalScrollDecorator {}
    }
    onFromTextChanged: {
        if (page.fromText == "Current position") {
            page.from = map.getPosition();
        } else if (page.fromText == "From") {
            page.from = null;
        } else {
            page.from = page.fromText;
            py.call_sync("poor.app.history.add_place", [page.fromText]);
        }
    }
    onStatusChanged: {
        if (page.status != PageStatus.Active) return;
        var uri = py.evaluate("poor.app.router.results_qml_uri");
        app.pageStack.pushAttached(uri);
    }
    onToTextChanged: {
        if (page.toText == "Current position") {
            page.to = map.getPosition();
        } else if (page.toText == "To") {
            page.to = null;
        } else {
            page.to = page.toText;
            py.call_sync("poor.app.history.add_place", [page.toText]);
        }
    }
}