/* Letag OS — diaporama affiché pendant l'installation. */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() { presentation.goToNextSlide(); }

    Timer {
        id: advanceTimer
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide { Image { source: "diapo1.png"; anchors.fill: parent; fillMode: Image.PreserveAspectFit } }
    Slide { Image { source: "diapo2.png"; anchors.fill: parent; fillMode: Image.PreserveAspectFit } }
    Slide { Image { source: "diapo3.png"; anchors.fill: parent; fillMode: Image.PreserveAspectFit } }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }
}
