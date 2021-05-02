QT += quick

CONFIG += c++11

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES +=

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    AnalysisOptions.qml \
    AnalysisView.qml \
    Controls/Button.qml \
    Controls/CheckBox.qml \
    Controls/ColorBox.qml \
    Controls/ComboBox.qml \
    Controls/Frame.qml \
    Controls/Frame.qml \
    Controls/Label.qml \
    Controls/MenuButton.qml \
    Controls/ProgressBar.qml \
    Controls/ScrollView.qml \
    Controls/TextField.qml \
    Controls/TreeButton.qml \
    Design.qml \
    DesignOptions.qml \
    FeatureDialog.qml \
    GeneralOptionsView.qml \
    LocalTraining.qml \
    MainView.qml \
    MenuButtonH.qml \
    Options.qml \
    OutputDialog.qml \
    Plus.png \
    SelectNeuralNetwork.qml \
    Templates/Button.qml \
    Templates/ButtonNN.qml \
    Templates/CheckBox.qml \
    Templates/ColorBox.qml \
    Templates/ComboBox.qml \
    Templates/Frame.qml \
    Templates/Label.qml \
    Templates/LayerButton.qml \
    Templates/MenuButton.qml \
    Templates/NewsPanel.qml \
    Templates/Pane.qml \
    Templates/ProgressBar.qml \
    Templates/RoundButton.qml \
    Templates/ScrollBar.qml \
    Templates/ScrollView.qml \
    Templates/ScrollableItem.qml \
    Templates/Slider.qml \
    Templates/SpinBox.qml \
    Templates/StopButton.qml \
    Templates/TextField.qml \
    Templates/TreeButton.qml \
    TrainingOptions.qml \
    TrainingPlot.qml \
    TrainingView.qml \
    ValidationPlot.qml \
    VisualisationView.qml \
    qtquickcontrols2.conf
