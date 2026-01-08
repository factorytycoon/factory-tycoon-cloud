// 1. 데이터가 하나도 없으면 알람을 울리지 않고 종료
if (ctx.results[0].hits.total.value == 0) {
    return false;
}

// 2. 검색된 모든 데이터(Hits)를 반복문으로 순회 (여기서는 16개 전체 검사)
for (def hit : ctx.results[0].hits.hits) {
    
    // --- [개별 데이터 파싱 시작] ---
    def source = hit._source;
    def sensors = source.sensors;

    // 변수 초기화 (값을 못 찾을 경우 0.0)
    def rpm = 0.0;
    def nois = 0.0;
    def disp = 0.0;

    // sensors 배열을 돌면서 각 센서의 값을 추출 (Type 확인)
    for (def item : sensors) {
        if (item.type == "rpm") { rpm = item.value; }
        if (item.type == "nois") { nois = item.value; }
        if (item.type == "disp") { disp = item.value; }
    }

    // --- [점수 계산 로직: Turning 공정 기준] ---
    int score_rpm = 1;
    int score_nois = 1;
    int score_disp = 1;

    // 1. RPM 점수 (Red: 500 미만)
    if (rpm < 500) { score_rpm = 10; }
    else if ((rpm >= 2400 && rpm <= 2699) || rpm > 3300) { score_rpm = 3; }
    else if (rpm >= 2700 && rpm <= 2899) { score_rpm = 2; }
    
    // 2. 소음(nois) 점수 (Red: 115 초과)
    if (nois > 115) { score_nois = 10; }
    else if (nois >= 106 && nois <= 114) { score_nois = 3; }
    else if (nois >= 99 && nois <= 105) { score_nois = 2; }

    // 3. 변위(disp) 점수 (Red: 1.00 초과)
    if (disp > 1.00) { score_disp = 10; }
    else if (disp >= 0.51 && disp <= 1.00) { score_disp = 3; }
    else if (disp >= 0.21 && disp <= 0.50) { score_disp = 2; }

    // 총점 합산
    int total_score = score_rpm + score_nois + score_disp;

    // --- [RED 판별] ---
    // 계산된 총점이 10점 이상이면, 즉시 True 반환 (알람 발생)
    if (total_score >= 10) {
        return true; 
    }
}

// 3. 모든 데이터를 다 검사했는데 10점 넘는 게 없으면 False (정상)
return false;