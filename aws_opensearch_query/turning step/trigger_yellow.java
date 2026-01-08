// 1. 데이터가 하나도 없으면 알람을 울리지 않고 종료
if (ctx.results[0].hits.total.value == 0) {
    return false;
}

// 2. 검색된 모든 데이터를 순회
for (def hit : ctx.results[0].hits.hits) {
    
    // --- [데이터 파싱] ---
    def source = hit._source;
    def sensors = source.sensors;

    // 변수 초기화
    def rpm = 0.0;
    def nois = 0.0;
    def disp = 0.0;

    // sensors 배열에서 값 추출
    for (def item : sensors) {
        if (item.type == "rpm") { rpm = item.value; }
        if (item.type == "nois") { nois = item.value; }
        if (item.type == "disp") { disp = item.value; }
    }

    // --- [점수 계산: Turning 공정 기준] ---
    // 기본값(Green)은 1점
    int score_rpm = 1;
    int score_nois = 1;
    int score_disp = 1;

    // 1. RPM 점수 산정 [cite: 42]
    // Red: 500 미만
    if (rpm < 500) { 
        score_rpm = 10; 
    }
    // Orange: 2400~2699 또는 3300 초과
    else if ((rpm >= 2400 && rpm <= 2699) || rpm > 3300) { 
        score_rpm = 3; 
    }
    // Yellow: 2700~2899
    else if (rpm >= 2700 && rpm <= 2899) { 
        score_rpm = 2; 
    }
    
    // 2. 소음(nois) 점수 산정 [cite: 40]
    // Red: 115 초과
    if (nois > 115) { 
        score_nois = 10; 
    }
    // Orange: 106~114
    else if (nois >= 106 && nois <= 114) { 
        score_nois = 3; 
    }
    // Yellow: 99~105
    else if (nois >= 99 && nois <= 105) { 
        score_nois = 2; 
    }

    // 3. 변위(disp) 점수 산정 [cite: 41]
    // Red: 1.00 초과
    if (disp > 1.00) { 
        score_disp = 10; 
    }
    // Orange: 0.51~1.00
    else if (disp >= 0.51 && disp <= 1.00) { 
        score_disp = 3; 
    }
    // Yellow: 0.21~0.50
    else if (disp >= 0.21 && disp <= 0.50) { 
        score_disp = 2; 
    }

    // 총점 합산
    int total_score = score_rpm + score_nois + score_disp;

    
    if (total_score >= 6 && total_score < 7) {
        return true; 
    }
}

// 해당되는 데이터가 없으면 false
return false;