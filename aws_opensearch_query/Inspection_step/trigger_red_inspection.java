// 1. 데이터가 없으면 종료
if (ctx.results[0].hits.total.value == 0) {
    return false;
}

// 2. 검색된 모든 데이터 순회
for (def hit : ctx.results[0].hits.hits) {
    
    // --- [데이터 파싱] ---
    def source = hit._source;
    def sensors = source.sensors;

    // 변수 초기화
    def weig = 0.0;
    def torq = 0.0;
    // phot는 RED 판별 로직에서 제외(기본값 처리)

    // sensors 배열에서 검수 공정 센서 값 추출 (weig, torq)
    for (def item : sensors) {
        if (item.type == "weig") { weig = item.value; }
        if (item.type == "torq") { torq = item.value; }
    }

    // --- [점수 계산: Inspection 공정 기준] ---
    // 기본값(Green)은 1점
    int score_weig = 1;
    int score_torq = 1;

    // 1. 무게(weig) 점수 산정
    // Red (10점): 400 미만 or 1700 초과
    if (weig < 400 || weig > 1700) { 
        score_weig = 10; 
    }
    // Yellow (6점): 400~999 or 1101~1700 (Orange 구간 별도 없음)
    else if ((weig >= 400 && weig <= 999) || (weig >= 1101 && weig <= 1700)) { 
        score_weig = 6; 
    }

    // 2. 모터 토크(torq) 점수 산정
    // Red (10점): 5 미만 or 55 초과
    if (torq < 5 || torq > 55) { 
        score_torq = 10; 
    }
    // Orange (7점): 46 ~ 55
    else if (torq >= 46 && torq <= 55) { 
        score_torq = 7; 
    }
    // Yellow (6점): 30 ~ 45
    else if (torq >= 30 && torq <= 45) { 
        score_torq = 6; 
    }

    // 포토 센서(phot)는 RED 트리거에 영향을 주지 않으므로 기본 점수 1점 유지
    int score_phot = 1;

    // 총점 합산
    int total_score = score_weig + score_torq + score_phot;

    // --- [RED 판별] ---
    // 총점이 10점 이상이면 RED(멈춤/고장) 상태로 판단하여 Trigger 발동
    if (total_score >= 10) {
        return true; 
    }
}

return false;