// Néo OS — préférences par défaut de Firefox ESR (modifiables dans about:config).
// Moins de processus de contenu : économise 100 à 300 Mo avec 4 Go de RAM.
pref("dom.ipc.processCount", 4);
// Décharger les onglets inactifs quand la mémoire manque.
pref("browser.tabs.unloadOnLowMemory", true);
// Sauvegarde de session toutes les 60 s au lieu de 15 s : moins d'écritures disque.
pref("browser.sessionstore.interval", 60000);
// Cache disque plafonné à 256 Mo.
pref("browser.cache.disk.smart_size.enabled", false);
pref("browser.cache.disk.capacity", 262144);
// Vidéo : pas de décodage matériel possible (nouveau + GT218). AV1 et VP9 sont
// très coûteux en logiciel pour un i5-650 ; les désactiver fait servir du H.264
// par la plupart des sites (YouTube compris), bien plus léger.
// Pour les réactiver : about:config, media.av1.enabled / media.mediasource.vp9.enabled
pref("media.av1.enabled", false);
pref("media.mediasource.vp9.enabled", false);
// Activer uBlock Origin installé par le système (paquet Debian).
pref("extensions.autoDisableScopes", 3);
pref("browser.aboutConfig.showWarning", false);
