server.database.backup :url file:///$dir/database
server.database.lock :action abort \
    :msg "The DaRIS database and stores are being backed up"
asset.archive.create :url file:///$dir/assets.aar
server.database.unlock
