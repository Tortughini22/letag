/* Letag OS — diaporama affiché pendant l'installation.
 * Les images ont une taille fixe et sont centrées : dans Calamares, une
 * « Slide » n'a pas de taille propre (anchors.fill donnerait une zone vide). */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 9000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image { source: "diapo1.png"; width: 800; height: 440; fillMode: Image.PreserveAspectFit; anchors.centerIn: parent }
    }
    Slide {
        Image { source: "diapo2.png"; width: 800; height: 440; fillMode: Image.PreserveAspectFit; anchors.centerIn: parent }
    }
    Slide {
        Image { source: "diapo3.png"; width: 800; height: 440; fillMode: Image.PreserveAspectFit; anchors.centerIn: parent }
    }

    function onActivate() { presentation.currentSlide = 0; }
    function onLeave() { }
}
