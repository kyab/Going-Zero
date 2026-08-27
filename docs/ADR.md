# Architecture Decision Record


## Filters

### Melodizer : リアルタイム相対ピッチシフト
　原音に対するTranspose. Cが基準で+-0移調。

  Latency
    入出力遅延と、音程追従遅延をわけて考えること。
    chat id : 69c3d04f-5da2-46d2-b795-ce827a06191d
    [ただし 「音の遅延」と「音程が変わるまでの遅延」は別物 です。演奏感で効くのは後者で、ここを 20ms にする方法はあります。]

    現状、音程追従遅延は割と小さくできている気がするが様子見。

　  入出力遅延がそれなりに発生するのでMelodierはfilterチェインの先頭に置いた。これにより後続のfilterの操作のリアルタイム性は変わらず確保されたが、
　　全体的にyoutube等の映像とのずれが生じる。MelodizerをDisableにすることでMelodizerによる遅延は消える。


　　原音の音程検出からのNote合わせ(Melodyne、ピッチ補正系)は音程検出必要。しかしリアルタイム性高い既存ソリューションもあるので深掘りの価値はある。
　
### QuickSampler
  トリガーでサンプリング、-> 全Note用に事前pitchshift -> それを鳴らす


